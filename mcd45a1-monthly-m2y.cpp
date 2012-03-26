#include "gdal_priv.h"
#include "cpl_conv.h" // for CPLMalloc()
 using namespace std;  
#include <iostream>
#include "cpl_string.h"
#include <string>

#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <time.h>
#include <string.h>


int getyday(int year, int mon, int day) {
  printf("function getyday(%d,%d,%d)\n",year, mon, day);
  time_t rawtime; 
  struct tm *timeinfo;

  time ( &rawtime );
  timeinfo = gmtime ( &rawtime );
  timeinfo->tm_year=year-1900;
  timeinfo->tm_mon=mon-1;
  timeinfo->tm_mday=day;
  
  if ( mktime(timeinfo) == -1 ) return -1;
  return timeinfo->tm_yday+1;
}

int getydayfromstr(const char* datestr) {
  int year,mon,day;
  sscanf(datestr,"%4d-%2d-%2d",&year,&mon,&day);
  return getyday(year,mon,day);
}


int main(int argc, char* argv[]) { 

   GDALDriver *poDriver;

   GDALDataset  *poSrcDS;//the first file which values will be changed
   GDALDataset *poDstDS;//for the final copy
   GDALDataset *poTmpDS;//for every file

   GDALRasterBand  *poTmpBand;
   GDALRasterBand  *poSrcBand;
   int             nBlockXSize, nBlockYSize;
   int             bGotMin, bGotMax;
   double          adfMinMax[2];
   
   short *buffer;
   short *srcBuffer;
   int   xsize;
   int   ysize;
   int c;
    char **papszOptions = NULL;
    
    //    char **ifiles;
    //    char *ifile;
    // int nifiles;
    char *ofile;
    if ( argc < 3 ) {
      cout<<"Usage: "<<argv[0]<<" ofile ifiles"<<endl;
      return 0; 
    }
    // string tmpstr("");
    char tmpstr[255];
    char *tmpstr2;
    int tmp_begin, tmp_end, tmp_date;
    int verbose = 0;
    
   // for(int i = 1; i < argc; i++)
   //    cout << argv[i] << endl;


    opterr = 0;
     
    while ((c = getopt (argc, argv, "o:q:hV")) != -1)
      switch (c)
	{
	case 'V':
	  verbose=1;
	  break;
	case 'h':
	  cout<<"Usage: "<<argv[0]<<" ofile ifiles"<<endl;
	  break;
	default:
      cout<<"Usage: "<<argv[0]<<" ofile ifiles"<<endl;
	  abort ();
	}
     
    //    printf("qa_t: %d qa_f: %s optind: %d\n",qa_threshold,qa_ofile,optind);
    // for (int i = optind; i < argc; i++)
    //   printf ("Non-option argument %s\n", argv[i]);


   // nifiles = argc-3;
   // cout<<nifiles<<"/"<<argc<<endl;

   ofile = argv[optind];
   
    GDALAllRegister();

   //read first dataset for copy
   // sprintf(tmpstr,"HDF4_EOS:EOS_GRID:\"%s\":MOD_GRID_Monthly_500km_BA:burndate",argv[optind+1]);
   // if (verbose!=0) cout<<"reading "<<tmpstr<<endl;

  poSrcDS = (GDALDataset *) GDALOpen( argv[optind+1], GA_ReadOnly );
   if( poSrcDS == NULL ) {
     cout<<"file not found or supported";
     return 0;
   }
   // poSrcDS->GetMetadataItem("RANGEBEGINNINGDATE");//=2003-01-01
string str2, str3;
 str2=string(basename(argv[optind+1]));
 str3=str2.substr(18,3);
 cout<<str2<<"-"<<str3<<endl;
 // tmp_begin=getydayfromstr(poSrcDS->GetMetadataItem("RANGEBEGINNINGDATE"));
 //   tmp_end=getydayfromstr(poSrcDS->GetMetadataItem("RANGEENDINGDATE"));

   poSrcBand = poSrcDS->GetRasterBand( 1 ); 
   xsize = poSrcBand->GetXSize();
   ysize = poSrcBand->GetYSize();
    // cout<<"nodataval: "<< poSrcBand->GetNoDataValue()<<endl;
    // cout<<xsize<<"*"<<ysize<<" "<<poSrcBand->GetMinimum()<<" "<<poSrcBand->GetMaximum()<<endl;
   srcBuffer = new short[xsize*ysize];
   poSrcBand->RasterIO( GF_Read, 0, 0, xsize, ysize, 
			srcBuffer, xsize, ysize, poSrcBand->GetRasterDataType(), 
			0, 0 );


   for(int i=0;i<xsize*ysize;i++) {
     tmp_date = srcBuffer[i];
     if(tmp_date>0 && tmp_date<=366) {
       // printf("= %d-%u-%d %d\n",i,qaSrcBuffer[i], srcBuffer[i],qa_threshold);
       if( tmp_date<tmp_begin | tmp_date>tmp_end) {
       	 srcBuffer[i] = 0;
       }
       // printf("! %d-%u-%d %d\n",i,qaSrcBuffer[i], srcBuffer[i],qa_threshold);
      }
   }

    //read others
   for(int k=optind+2;k<argc;k++) {

     poTmpDS = (GDALDataset *) GDALOpen( argv[k], GA_ReadOnly );

     if( poTmpDS == NULL ) {
       cout<<"file "<<tmpstr<<" not found or supported";
       return 0;
     }

     tmp_begin=getydayfromstr(poTmpDS->GetMetadataItem("RANGEBEGINNINGDATE"));
     tmp_end=getydayfromstr(poTmpDS->GetMetadataItem("RANGEENDINGDATE"));

    poTmpBand = poTmpDS->GetRasterBand( 1 ); 
     if( poTmpDS == NULL ) {
      cout<<"rasterband not found";
      return 0;
    }
    // printf("opened %d\n",poTmpBand->GetRasterDataType());    
    // printf("NUMBERBURNEDPIXELS: %s\n",poTmpDS->GetMetadataItem("NUMBERBURNEDPIXELS"));
    buffer = new short[xsize*ysize];
    poTmpBand->RasterIO( GF_Read, 0, 0, xsize, ysize, 
		      buffer, xsize, ysize, poTmpBand->GetRasterDataType(), 
		      0, 0 );


    for(int i=0;i<xsize*ysize;i++) {
   tmp_date = buffer[i];
     if(tmp_date>0 && tmp_date<=366) {
       // printf("\n= %d-%u-%d %d\n",i,qaBuffer[i], buffer[i],qa_threshold);
       // printf("= %d-%u-%d %d\n",i,qaSrcBuffer[i], srcBuffer[i],qa_threshold);
       if(!( tmp_date<tmp_begin | tmp_date>tmp_end )) {
	 srcBuffer[i] = buffer[i];
       }
       // printf("- %d-%u-%d %d\n",i,qaSrcBuffer[i], srcBuffer[i],qa_threshold);
      }
    }

    delete [] buffer;
    GDALClose( (GDALDatasetH) poTmpDS );

  }

   //write new data to buffer
   int burn_count=0, unburn_count=0;
   for(int i=0;i<xsize*ysize;i++) {
      if(srcBuffer[i]>366) { srcBuffer[i] = 0; unburn_count++; }
      else if((srcBuffer[i]>0)) burn_count++;
      else  unburn_count++;
      // if((srcBuffer[i]>0)) burn_count++;
      // else  unburn_count++;
   }
   poSrcBand->SetNoDataValue(0.0);
   poSrcBand->RasterIO( GF_Write, 0, 0, xsize, ysize, 
   			srcBuffer, xsize, ysize, poSrcBand->GetRasterDataType(), 
   			0, 0 );

   //   metadata = poSrcDataset->GetMetadata("");
   //   tmpstr=poSrcDS->GetMetadataItem("NUMBERBURNEDPIXELS");
   poSrcDS->SetMetadata(NULL,NULL);
   sprintf(tmpstr,"%d",burn_count);
   poSrcDS->SetMetadataItem("NUMBERBURNEDPIXELS",tmpstr);
   sprintf(tmpstr,"%d",unburn_count);
   poSrcDS->SetMetadataItem("NUMBEROTHERPIXELS",tmpstr);
   // poSrcDS->SetMetadataItem("NUMBERINSUFFICIENTPIXELS","0");
   sprintf(tmpstr,"%f",(100.0*burn_count)/(xsize*ysize));
   poSrcDS->SetMetadataItem("PERCENTBURNED",tmpstr);
   // printf("burn_count: %d unburn_count: %d NUMBERBURNEDPIXELS: %s\n",burn_count,unburn_count,poSrcDS->GetMetadataItem("NUMBERBURNEDPIXELS"));

   //write the final file
   poDriver = GetGDALDriverManager()->GetDriverByName("GTIFF");
   papszOptions = CSLSetNameValue( papszOptions, "COMPRESS", "PACKBITS" );
   
   printf("writing to file %s\n",ofile);
   poDstDS = poDriver->CreateCopy( ofile, poSrcDS, FALSE,
   papszOptions, GDALTermProgress, NULL );
   
    /* Once we're done, close properly the dataset */
   if( poDstDS != NULL )
     GDALClose( (GDALDatasetH) poDstDS );

     // cout<<qa0<<"-"<<qa1<<"-"<<qa2<<"-"<<qa3<<"-"<<qa4<<"-"<<qatotal<<"-"<<burn_count<<"-"<<tmpstr<<"-"<<(qatotal-qa0)<<endl;

     

   //tmp consistency check
   for(int i=0;i<xsize*ysize;i++) {
     // if(qaSrcBuffer[i]!=0 && (srcBuffer[i]==0 | srcBuffer[i]>366)) 
     // if(qaSrcBuffer[i]>qa_threshold)
     //   printf("FUCK1 %d-%d-%d\n",i,qaSrcBuffer[i],srcBuffer[i]);
      // if(srcBuffer[i]>0 && srcBuffer[i]<=366 && qaSrcBuffer!=0)  printf("FUCK1 %d-%d-%d\n",i,qaSrcBuffer[i],srcBuffer[i]);
   }

   delete [] srcBuffer;
   GDALClose( (GDALDatasetH) poSrcDS );

}
