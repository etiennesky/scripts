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



int getyday(int year, int mon, int day) {
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
   GDALDataset *poSrcQaDS;//for every file
   GDALDataset *poTmpQaDS;//for every file

   GDALRasterBand  *poTmpBand;
   GDALRasterBand  *poTmpQaBand;
   GDALRasterBand  *poSrcBand;
   GDALRasterBand  *poSrcQaBand;
   int             nBlockXSize, nBlockYSize;
   int             bGotMin, bGotMax;
   double          adfMinMax[2];
   
   short *buffer;
   GByte *qaBuffer;
   // short *qaBuffer;
   GByte *qaSrcBuffer;
   // short *qaSrcBuffer;
   GByte qa_threshold = 4;
   // short qa_threshold = 4;
   short *srcBuffer;
   int   xsize;
   int   ysize;
   int c;
    char **papszOptions = NULL;
    
    //    char **ifiles;
    //    char *ifile;
    // int nifiles;
    char *qa_ofile = NULL;
    if ( argc < 3 ) {
      cout<<"Usage: "<<argv[0]<<" [-q qa_threshhold (4)] [-o qa_file] ofile ifiles"<<endl;
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
	case 'o':
	  qa_ofile = optarg;
	  break;
	case 'q':
	  qa_threshold = atoi(optarg);
	  //qa_threshold = optarg[0];
	  break;
	case 'V':
	  verbose=1;
	  break;
	case 'h':
	  cout<<"Usage: "<<argv[0]<<" [-q qa_threshhold (4)] [-o qa_file] ofile ifiles"<<endl;
	  break;
	default:
	  cout<<"Usage: "<<argv[0]<<" [-q qa_threshhold (4)] [-o qa_file] ofile ifiles"<<endl;
	  abort ();
	}
     
    printf("qa_t: %d qa_f: %s optind: %d\n",qa_threshold,qa_ofile,optind);
    // for (int i = optind; i < argc; i++)
    //   printf ("Non-option argument %s\n", argv[i]);


   // nifiles = argc-3;
   // cout<<nifiles<<"/"<<argc<<endl;

   // qa_threshold = atoi(argv[1]);
   ofile = argv[optind];
   
   // cout<<"-"<<qa_threshold<<"-"<<ofile<<endl;


    GDALAllRegister();

   //read first dataset for copy
   sprintf(tmpstr,"HDF4_EOS:EOS_GRID:\"%s\":MOD_GRID_Monthly_500km_BA:burndate",argv[optind+1]);
   if (verbose!=0) cout<<"reading "<<tmpstr<<endl;

  poSrcDS = (GDALDataset *) GDALOpen( tmpstr, GA_ReadOnly );
   if( poSrcDS == NULL ) {
     cout<<"file not found or supported";
     return 0;
   }
   // poSrcDS->GetMetadataItem("RANGEBEGINNINGDATE");//=2003-01-01
   tmp_begin=getydayfromstr(poSrcDS->GetMetadataItem("RANGEBEGINNINGDATE"));
   tmp_end=getydayfromstr(poSrcDS->GetMetadataItem("RANGEENDINGDATE"));

   poSrcBand = poSrcDS->GetRasterBand( 1 ); 
   xsize = poSrcBand->GetXSize();
   ysize = poSrcBand->GetYSize();
    // cout<<"nodataval: "<< poSrcBand->GetNoDataValue()<<endl;
    // cout<<xsize<<"*"<<ysize<<" "<<poSrcBand->GetMinimum()<<" "<<poSrcBand->GetMaximum()<<endl;
   srcBuffer = new short[xsize*ysize];
   poSrcBand->RasterIO( GF_Read, 0, 0, xsize, ysize, 
			srcBuffer, xsize, ysize, poSrcBand->GetRasterDataType(), 
			0, 0 );

   // test for qa
   sprintf(tmpstr,"HDF4_EOS:EOS_GRID:\"%s\":MOD_GRID_Monthly_500km_BA:ba_qa",argv[optind+1]);
   if (verbose!=0) cout<<"reading "<<tmpstr<<endl;
   poSrcQaDS = (GDALDataset *) GDALOpen( tmpstr, GA_ReadOnly );
   if( poSrcQaDS == NULL ) {
     cout<<"file "<<tmpstr<<" not found or supported";
     return 0;
   }
   poSrcQaBand = poSrcQaDS->GetRasterBand( 1 ); 
   if( poSrcQaDS == NULL ) {
     cout<<"rasterband not found";
     return 0;
   }
   qaSrcBuffer = new GByte[xsize*ysize];
   // qaSrcBuffer = new short[xsize*ysize];
   poSrcQaBand->RasterIO( GF_Read, 0, 0, xsize, ysize, 
			  qaSrcBuffer, xsize, ysize, poSrcQaBand->GetRasterDataType(), 
			  0, 0 );

   for(int i=0;i<xsize*ysize;i++) {
     tmp_date = srcBuffer[i];
     if(tmp_date>0 && tmp_date<=366) {
       // printf("= %d-%u-%d %d\n",i,qaSrcBuffer[i], srcBuffer[i],qa_threshold);
       if( tmp_date<tmp_begin | tmp_date>tmp_end | qaSrcBuffer[i]>qa_threshold) {
       	 srcBuffer[i] = 0;
       	 qaSrcBuffer[i] = 0;
       }
       // printf("! %d-%u-%d %d\n",i,qaSrcBuffer[i], srcBuffer[i],qa_threshold);
      }
   }
   // delete [] qaBuffer;
   // GDALClose( (GDALDatasetH) poTmpQaDS );

    //read others
   for(int k=optind+2;k<argc;k++) {

     sprintf(tmpstr,"HDF4_EOS:EOS_GRID:\"%s\":MOD_GRID_Monthly_500km_BA:burndate",argv[k]);
     if (verbose!=0)  cout<<"reading "<<tmpstr<<endl;
     poTmpDS = (GDALDataset *) GDALOpen( tmpstr, GA_ReadOnly );

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

    sprintf(tmpstr,"HDF4_EOS:EOS_GRID:\"%s\":MOD_GRID_Monthly_500km_BA:ba_qa",argv[k]);
    if (verbose!=0) cout<<"reading "<<tmpstr<<endl;
    poTmpQaDS = (GDALDataset *) GDALOpen( tmpstr, GA_ReadOnly );
    
    if( poTmpQaDS == NULL ) {
      cout<<"file "<<tmpstr<<" not found or supported";
      return 0;
    }

    poTmpQaBand = poTmpQaDS->GetRasterBand( 1 ); 
     if( poTmpQaDS == NULL ) {
      cout<<"rasterband not found";
      return 0;
    }
    // printf("opened %d\n",poTmpQaBand->GetRasterDataType());    
    qaBuffer = new GByte[xsize*ysize];
    // qaBuffer = new short[xsize*ysize];
    poTmpQaBand->RasterIO( GF_Read, 0, 0, xsize, ysize, 
		      qaBuffer, xsize, ysize, poTmpQaBand->GetRasterDataType(), 
		      0, 0 );


    for(int i=0;i<xsize*ysize;i++) {
   tmp_date = buffer[i];
     if(tmp_date>0 && tmp_date<=366) {
       // printf("\n= %d-%u-%d %d\n",i,qaBuffer[i], buffer[i],qa_threshold);
       // printf("= %d-%u-%d %d\n",i,qaSrcBuffer[i], srcBuffer[i],qa_threshold);
       if(!( tmp_date<tmp_begin | tmp_date>tmp_end | qaBuffer[i]>qa_threshold)) {
	 srcBuffer[i] = buffer[i];
	 qaSrcBuffer[i] = qaBuffer[i];
       }
       // printf("- %d-%u-%d %d\n",i,qaSrcBuffer[i], srcBuffer[i],qa_threshold);
      }
    }

    delete [] buffer;
    delete [] qaBuffer;
    GDALClose( (GDALDatasetH) poTmpDS );
    GDALClose( (GDALDatasetH) poTmpQaDS );

  }

   //write new data to buffer
   int burn_count=0, unburn_count=0;
   for(int i=0;i<xsize*ysize;i++) {
      if(srcBuffer[i]>366) { srcBuffer[i] = 0; qaSrcBuffer[i] = 0; unburn_count++; }
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

   //write qa if necessary
   if ( qa_ofile != NULL) {
     int qa0=0, qa1=0, qa2=0, qa3=0, qa4=0,qatotal=0,burn_count=0, unburn_count=0;
     for(int i=0;i<xsize*ysize;i++) {
       if(qaSrcBuffer[i]==0) qa0++;
       else if(qaSrcBuffer[i]==1) qa1++;
       else if(qaSrcBuffer[i]==2) qa2++;
       else if(qaSrcBuffer[i]==3) qa3++;
       else if(qaSrcBuffer[i]==4) qa4++;
       else {qaSrcBuffer[i]==0; qa0++;}
       if(qaSrcBuffer[i]!=0) burn_count++;
       else unburn_count++;
     }
     qatotal = qa0+qa1+qa2+qa3+qa4;
     // cout<<qa0<<"-"<<qa1<<"-"<<qa2<<"-"<<qa3<<"-"<<qa4<<"-"<<qatotal<<"-"<<burn_count<<"-"<<tmpstr<<"-"<<(qatotal-qa0)<<endl;

     poSrcQaDS->SetMetadata(NULL,NULL);
     sprintf(tmpstr,"%d",((100*qa1)/(qatotal-qa0)));
     poSrcQaDS->SetMetadataItem("QA1PERCENT",tmpstr);
     sprintf(tmpstr,"%d",((100*qa2)/(qatotal-qa0)));
     poSrcQaDS->SetMetadataItem("QA2PERCENT",tmpstr);
     sprintf(tmpstr,"%d",((100*qa3)/(qatotal-qa0)));
     poSrcQaDS->SetMetadataItem("QA3PERCENT",tmpstr);
     sprintf(tmpstr,"%d",((100*qa4)/(qatotal-qa0)));
     poSrcQaDS->SetMetadataItem("QA4PERCENT",tmpstr);
     sprintf(tmpstr,"%d",burn_count);
     poSrcQaDS->SetMetadataItem("NUMBERBURNEDPIXELS",tmpstr);
     sprintf(tmpstr,"%d",unburn_count);
     poSrcQaDS->SetMetadataItem("NUMBEROTHERPIXELS",tmpstr);
     // poSrcQaDS->SetMetadataItem("NUMBERINSUFFICIENTPIXELS","0");
     sprintf(tmpstr,"%f",(100.0*burn_count)/(xsize*ysize));
     poSrcQaDS->SetMetadataItem("PERCENTBURNED",tmpstr);
     
     poSrcQaBand->SetNoDataValue(0.0);
     poSrcQaBand->RasterIO( GF_Write, 0, 0, xsize, ysize, 
			    qaSrcBuffer, xsize, ysize, poSrcQaBand->GetRasterDataType(), 
			    0, 0 );
     
   printf("writing to file %s\n",qa_ofile);
   poDstDS = poDriver->CreateCopy( qa_ofile, poSrcQaDS, FALSE,
   papszOptions, GDALTermProgress, NULL );
   
    /* Once we're done, close properly the dataset */
   if( poDstDS != NULL )
     GDALClose( (GDALDatasetH) poDstDS );

   }   


   //tmp consistency check
   for(int i=0;i<xsize*ysize;i++) {
     // if(qaSrcBuffer[i]!=0 && (srcBuffer[i]==0 | srcBuffer[i]>366)) 
     // if(qaSrcBuffer[i]>qa_threshold)
     //   printf("FUCK1 %d-%d-%d\n",i,qaSrcBuffer[i],srcBuffer[i]);
      // if(srcBuffer[i]>0 && srcBuffer[i]<=366 && qaSrcBuffer!=0)  printf("FUCK1 %d-%d-%d\n",i,qaSrcBuffer[i],srcBuffer[i]);
   }

   delete [] srcBuffer;
   GDALClose( (GDALDatasetH) poSrcDS );
   delete [] qaSrcBuffer;
   GDALClose( (GDALDatasetH) poSrcQaDS );

}
