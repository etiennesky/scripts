/******************************************************************************
 * $Id: gdal_translate.cpp 21386 2011-01-03 20:17:11Z rouault $
 *
 * Project:  GDAL Utilities
 * Purpose:  GDAL Image Translator Program
 * Author:   Frank Warmerdam, warmerdam@pobox.com
 *
 ******************************************************************************
 * Copyright (c) 1998, 2002, Frank Warmerdam
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 ****************************************************************************/

#include "cpl_vsi.h"
#include "cpl_conv.h"
#include "cpl_string.h"
#include "gdal_priv.h"
#include "ogr_spatialref.h"
//#include "vrt/vrtdataset.h"

CPL_CVSID("$Id: gdal_translate.cpp 21386 2011-01-03 20:17:11Z rouault $");

static int ArgIsNumeric( const char * );
static void AttachMetadata( GDALDatasetH, char ** );
static void CopyBandInfo( GDALRasterBand * poSrcBand, GDALRasterBand * poDstBand,
                            int bCanCopyStatsMetadata, int bCopyScale, int bCopyNoData );
static int bSubCall = FALSE;

/*  ******************************************************************* */
/*                               Usage()                                */
/* ******************************************************************** */

static void Usage()

{
    int	iDr;
        
    printf( "Usage: gdal_translate [--help-general]\n"
            "       [-ot {Byte/Int16/UInt16/UInt32/Int32/Float32/Float64/\n"
            "             CInt16/CInt32/CFloat32/CFloat64}] [-strict]\n"
            "       [-of format] [-b band] [-mask band] [-expand {gray|rgb|rgba}]\n"
            "       [-outsize xsize[%%] ysize[%%]]\n"
            "       [-unscale] [-scale [src_min src_max [dst_min dst_max]]]\n"
            "       [-srcwin xoff yoff xsize ysize] [-projwin ulx uly lrx lry]\n"
            "       [-a_srs srs_def] [-a_ullr ulx uly lrx lry] [-a_nodata value]\n"
            "       [-gcp pixel line easting northing [elevation]]*\n" 
            "       [-mo \"META-TAG=VALUE\"]* [-q] [-sds]\n"
            "       [-co \"NAME=VALUE\"]* [-stats]\n"
            "       src_dataset dst_dataset\n\n" );

    printf( "%s\n\n", GDALVersionInfo( "--version" ) );
    printf( "The following format drivers are configured and support output:\n" );
    for( iDr = 0; iDr < GDALGetDriverCount(); iDr++ )
    {
        GDALDriverH hDriver = GDALGetDriver(iDr);
        
        if( GDALGetMetadataItem( hDriver, GDAL_DCAP_CREATE, NULL ) != NULL
            || GDALGetMetadataItem( hDriver, GDAL_DCAP_CREATECOPY,
                                    NULL ) != NULL )
        {
            printf( "  %s: %s\n",
                    GDALGetDriverShortName( hDriver ),
                    GDALGetDriverLongName( hDriver ) );
        }
    }
}

/************************************************************************/
/*                             ProxyMain()                              */
/************************************************************************/

enum
{
    MASK_DISABLED,
    MASK_AUTO,
    MASK_USER
};

static int ProxyMain( int argc, char ** argv )

{
    // GDALDatasetH	hDataset, hOutDS;
    // int			i;
    // int			nRasterXSize, nRasterYSize;
    // const char		*pszSource=NULL, *pszDest=NULL, *pszFormat = "GTiff";
    // GDALDriverH		hDriver;
    // int			*panBandList = NULL; /* negative value of panBandList[i] means mask band of ABS(panBandList[i]) */
    // int         nBandCount = 0, bDefBands = TRUE;
    // double		adfGeoTransform[6];
    // GDALDataType	eOutputType = GDT_Unknown;
    // int			nOXSize = 0, nOYSize = 0;
    // char		*pszOXSize=NULL, *pszOYSize=NULL;
    // char                **papszCreateOptions = NULL;
    // int                 anSrcWin[4], bStrict = FALSE;
    // const char          *pszProjection;
    // int                 bScale = FALSE, bHaveScaleSrc = FALSE, bUnscale=FALSE;
    // double	        dfScaleSrcMin=0.0, dfScaleSrcMax=255.0;
    // double              dfScaleDstMin=0.0, dfScaleDstMax=255.0;
    // double              dfULX, dfULY, dfLRX, dfLRY;
    // char                **papszMetadataOptions = NULL;
    // char                *pszOutputSRS = NULL;
    // int                 bQuiet = FALSE, bGotBounds = FALSE;
    // GDALProgressFunc    pfnProgress = GDALTermProgress;
    // int                 nGCPCount = 0;
    // GDAL_GCP            *pasGCPs = NULL;
    // int                 iSrcFileArg = -1, iDstFileArg = -1;
    // int                 bCopySubDatasets = FALSE;
    // double              adfULLR[4] = { 0,0,0,0 };
    // int                 bSetNoData = FALSE;
    // int                 bUnsetNoData = FALSE;
    // double		dfNoDataReal = 0.0;
    // int                 nRGBExpand = 0;
    // int                 bParsedMaskArgument = FALSE;
    // int                 eMaskMode = MASK_AUTO;
    // int                 nMaskBand = 0; /* negative value means mask band of ABS(nMaskBand) */
    // int                 bStats = FALSE, bApproxStats = FALSE;

    // GDALDatasetH	hDataset, hOutDS;
  GDALDataset	*mDataset = NULL;
    GDALDataset	*hOutDS = NULL;
    int			i;
    int			nRasterXSize, nRasterYSize;
    const char		*pszSource=NULL, *pszDest=NULL, *pszFormat = "GTiff";
    // GDALDriverH		hDriver;
    GDALDriver		*hDriver;
    GDALDataType	eOutputType = GDT_Unknown;
    char                **papszCreateOptions = NULL;
    int                 bStrict = FALSE;
    int                 bQuiet = FALSE;
    GDALProgressFunc    pfnProgress = GDALTermProgress;
    int                 iSrcFileArg = -1, iDstFileArg = -1;
    int                 bSetNoData = FALSE;
    int                 bUnsetNoData = FALSE;
    double		dfNoDataReal = 0.0;

    GDALRasterBand  *inBand = NULL;    
    GDALRasterBand  *outBand = NULL;    
   GByte *srcBuffer;
   double adfGeoTransform[6];
   int nRasterCount;

    /* Check strict compilation and runtime library version as we use C++ API */
    if (! GDAL_CHECK_VERSION(argv[0]))
        exit(1);

    /* Must process GDAL_SKIP before GDALAllRegister(), but we can't call */
    /* GDALGeneralCmdLineProcessor before it needs the drivers to be registered */
    /* for the --format or --formats options */
    for( i = 1; i < argc; i++ )
    {
        if( EQUAL(argv[i],"--config") && i + 2 < argc && EQUAL(argv[i + 1], "GDAL_SKIP") )
        {
            CPLSetConfigOption( argv[i+1], argv[i+2] );

            i += 2;
        }
    }

/* -------------------------------------------------------------------- */
/*      Register standard GDAL drivers, and process generic GDAL        */
/*      command options.                                                */
/* -------------------------------------------------------------------- */
    GDALAllRegister();
    argc = GDALGeneralCmdLineProcessor( argc, &argv, 0 );
    if( argc < 1 )
        exit( -argc );

/* -------------------------------------------------------------------- */
/*      Handle command line arguments.                                  */
/* -------------------------------------------------------------------- */
    for( i = 1; i < argc; i++ )
    {
        if( EQUAL(argv[i],"-of") && i < argc-1 )
            pszFormat = argv[++i];

        else if( EQUAL(argv[i],"-q") || EQUAL(argv[i],"-quiet") )
        {
            bQuiet = TRUE;
            pfnProgress = GDALDummyProgress;
        }

        else if( EQUAL(argv[i],"-ot") && i < argc-1 )
        {
            int	iType;
            
            for( iType = 1; iType < GDT_TypeCount; iType++ )
            {
                if( GDALGetDataTypeName((GDALDataType)iType) != NULL
                    && EQUAL(GDALGetDataTypeName((GDALDataType)iType),
                             argv[i+1]) )
                {
                    eOutputType = (GDALDataType) iType;
                }
            }

            if( eOutputType == GDT_Unknown )
            {
                printf( "Unknown output pixel type: %s\n", argv[i+1] );
                Usage();
                GDALDestroyDriverManager();
                exit( 2 );
            }
            i++;
        }
        else if( EQUAL(argv[i],"-not_strict")  )
            bStrict = FALSE;
            
        else if( EQUAL(argv[i],"-strict")  )
            bStrict = TRUE;
            
        else if( EQUAL(argv[i],"-a_nodata") && i < argc - 1 )
        {
            if (EQUAL(argv[i+1], "none"))
            {
                bUnsetNoData = TRUE;
            }
            else
            {
                bSetNoData = TRUE;
                dfNoDataReal = CPLAtofM(argv[i+1]);
            }
            i += 1;
        }   

        else if( EQUAL(argv[i],"-co") && i < argc-1 )
        {
            papszCreateOptions = CSLAddString( papszCreateOptions, argv[++i] );
        }   


        else if( argv[i][0] == '-' )
        {
            printf( "Option %s incomplete, or not recognised.\n\n", 
                    argv[i] );
            Usage();
            GDALDestroyDriverManager();
            exit( 2 );
        }
        else if( pszSource == NULL )
        {
            iSrcFileArg = i;
            pszSource = argv[i];
        }
        else if( pszDest == NULL )
        {
            pszDest = argv[i];
            iDstFileArg = i;
        }

        else
        {
            printf( "Too many command options.\n\n" );
            Usage();
            GDALDestroyDriverManager();
            exit( 2 );
        }
    }

    if( pszDest == NULL )
    {
        Usage();
        GDALDestroyDriverManager();
        exit( 10 );
    }

    if ( strcmp(pszSource, pszDest) == 0)
    {
        fprintf(stderr, "Source and destination datasets must be different.\n");
        GDALDestroyDriverManager();
        exit( 1 );
    }

/* -------------------------------------------------------------------- */
/*      Attempt to open source file.                                    */
/* -------------------------------------------------------------------- */

    // hDataset = GDALOpenShared( pszSource, GA_ReadOnly );
    hDataset = (GDALDataset *) GDALOpen(pszSource, GA_ReadOnly );
   
    if( hDataset == NULL )
    {
        fprintf( stderr,
                 "GDALOpen failed - %d\n%s\n",
                 CPLGetLastErrorNo(), CPLGetLastErrorMsg() );
        GDALDestroyDriverManager();
        exit( 1 );
    }


/* -------------------------------------------------------------------- */
/*      Collect some information from the source file.                  */
/* -------------------------------------------------------------------- */
    // nRasterXSize = GDALGetRasterXSize( hDataset );
    // nRasterYSize = GDALGetRasterYSize( hDataset );
    nRasterXSize = hDataset->GetRasterXSize();
    nRasterYSize = hDataset->GetRasterYSize();

    if( !bQuiet )
        printf( "Input file size is %d, %d\n", nRasterXSize, nRasterYSize );


/* -------------------------------------------------------------------- */
/*      Find the output driver.                                         */
/* -------------------------------------------------------------------- */
    hDriver = GetGDALDriverManager()->GetDriverByName( pszFormat );
    if( hDriver == NULL )
    {
        int	iDr;
        
        printf( "Output driver `%s' not recognised.\n", pszFormat );
        printf( "The following format drivers are configured and support output:\n" );
        for( iDr = 0; iDr < GDALGetDriverCount(); iDr++ )
        {
            GDALDriverH hDriver = GDALGetDriver(iDr);

            if( GDALGetMetadataItem( hDriver, GDAL_DCAP_CREATE, NULL ) != NULL
                || GDALGetMetadataItem( hDriver, GDAL_DCAP_CREATECOPY,
                                        NULL ) != NULL )
            {
                printf( "  %s: %s\n",
                        GDALGetDriverShortName( hDriver  ),
                        GDALGetDriverLongName( hDriver ) );
            }
        }
        printf( "\n" );
        Usage();
        
        GDALClose(  (GDALDatasetH) hDataset );
        GDALDestroyDriverManager();
        CSLDestroy( argv );
        CSLDestroy( papszCreateOptions );
        exit( 1 );
    }


/* -------------------------------------------------------------------- */
/*      Create Dataset and copy info                                    */
/* -------------------------------------------------------------------- */

    nRasterCount = hDataset->GetRasterCount();
    printf("creating\n");
    hOutDS = hDriver->Create( pszDest, nRasterXSize, nRasterYSize,
			     nRasterCount, GDT_Byte, papszCreateOptions);
    printf("created\n");

 
    if( hOutDS != NULL )
       {

	 hDataset->GetGeoTransform( adfGeoTransform);
	 hOutDS->SetGeoTransform( adfGeoTransform );
	 hOutDS->SetProjection( hDataset->GetProjectionRef() );

/* ==================================================================== */
/*      Process all bands.                                              */
/* ==================================================================== */
	 // if (0)
    for( i = 1; i < nRasterCount+1; i++ )
    {
      printf("TMP ET band %d\n",i);
      inBand = hDataset->GetRasterBand( i ); 
      // hOutDS->AddBand(GDT_Byte);
      inBand = hOutDS->GetRasterBand( i );      
      nRasterXSize = inBand->GetXSize( );
      nRasterYSize = inBand->GetYSize( );
      srcBuffer = new GByte[nRasterXSize * nRasterXSize];
    printf("reading\n");
      inBand->RasterIO( GF_Read, 0, 0, nRasterXSize, nRasterYSize, 
      			srcBuffer, nRasterXSize, nRasterYSize, GDT_Byte, 
      			0, 0 );
    printf("read\n");
    printf("writing\n");

      outBand->RasterIO( GF_Write, 0, 0, nRasterXSize, nRasterYSize, 
      			srcBuffer, nRasterXSize, nRasterYSize, GDT_Byte, 
      			0, 0 );
    printf("wrote\n");

      delete [] srcBuffer;
    }
       }
 

    if( hOutDS != NULL )
      GDALClose(  (GDALDatasetH) hOutDS );
    if( hDataset != NULL )
      GDALClose(  (GDALDatasetH) hDataset );


    GDALDumpOpenDatasets( stderr );
    GDALDestroyDriverManager();
    CSLDestroy( argv );
    CSLDestroy( papszCreateOptions );
    
    return hOutDS == NULL;
}


/************************************************************************/
/*                            ArgIsNumeric()                            */
/************************************************************************/

int ArgIsNumeric( const char *pszArg )

{
    if( pszArg[0] == '-' )
        pszArg++;

    if( *pszArg == '\0' )
        return FALSE;

    while( *pszArg != '\0' )
    {
        if( (*pszArg < '0' || *pszArg > '9') && *pszArg != '.' )
            return FALSE;
        pszArg++;
    }
        
    return TRUE;
}

/************************************************************************/
/*                           CopyBandInfo()                            */
/************************************************************************/

/* A bit of a clone of VRTRasterBand::CopyCommonInfoFrom(), but we need */
/* more and more custom behaviour in the context of gdal_translate ... */

static void CopyBandInfo( GDALRasterBand * poSrcBand, GDALRasterBand * poDstBand,
                          int bCanCopyStatsMetadata, int bCopyScale, int bCopyNoData )

{
    int bSuccess;
    double dfNoData;

    if (bCanCopyStatsMetadata)
    {
        poDstBand->SetMetadata( poSrcBand->GetMetadata() );
    }
    else
    {
        char** papszMetadata = poSrcBand->GetMetadata();
        char** papszMetadataNew = NULL;
        for( int i = 0; papszMetadata != NULL && papszMetadata[i] != NULL; i++ )
        {
            if (strncmp(papszMetadata[i], "STATISTICS_", 11) != 0)
                papszMetadataNew = CSLAddString(papszMetadataNew, papszMetadata[i]);
        }
        poDstBand->SetMetadata( papszMetadataNew );
        CSLDestroy(papszMetadataNew);
    }

    poDstBand->SetColorTable( poSrcBand->GetColorTable() );
    poDstBand->SetColorInterpretation(poSrcBand->GetColorInterpretation());
    if( strlen(poSrcBand->GetDescription()) > 0 )
        poDstBand->SetDescription( poSrcBand->GetDescription() );

    if (bCopyNoData)
    {
        dfNoData = poSrcBand->GetNoDataValue( &bSuccess );
        if( bSuccess )
            poDstBand->SetNoDataValue( dfNoData );
    }

    if (bCopyScale)
    {
        poDstBand->SetOffset( poSrcBand->GetOffset() );
        poDstBand->SetScale( poSrcBand->GetScale() );
    }

    poDstBand->SetCategoryNames( poSrcBand->GetCategoryNames() );
    if( !EQUAL(poSrcBand->GetUnitType(),"") )
        poDstBand->SetUnitType( poSrcBand->GetUnitType() );
}

/************************************************************************/
/*                                main()                                */
/************************************************************************/

int main( int argc, char ** argv )

{
    return ProxyMain( argc, argv );
}


