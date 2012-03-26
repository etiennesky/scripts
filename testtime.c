
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
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

int getymd(int year, int yday, char *retval) {
    time_t rawtime; 
    struct tm timeinfo;
    char tmpstr[100];
  
    timeinfo.tm_year=year-1900;
    timeinfo.tm_mon=0;
    timeinfo.tm_mday=yday;
    timeinfo.tm_isdst=-1;
    timeinfo.tm_hour=0;
    timeinfo.tm_min=0;
    timeinfo.tm_sec=0;

//  timeinfo.tm_year=year-1900;
//    timeinfo.tm_yday=yday-1;
    
    if ( mktime(&timeinfo) == -1 ) return -1;
    sprintf(tmpstr,"%4d-%02d-%02d", (timeinfo.tm_year)+1900,
            (timeinfo.tm_mon)+1,(timeinfo.tm_mday));
    strcpy(retval,tmpstr);
    return 0;
}


int main(int argc, char* argv[]) { 
    char *arg_str;
    int arg_year, arg_yday;
    if ( argc < 2 || argc > 3 ) {
        printf("Usage: %s yyyy doy | yyyy-mm-dd \n",argv[0]);
        return 0; 
    }
    if(argc==2) {
        arg_str = argv[1];
        if(strlen(arg_str)!=10) {
            printf("Usage: %s yyyy doy | yyyy-mm-dd \n",argv[0]);
            return 0; 
        }
        printf("input: %s\n",arg_str);
        printf("output: %d\n",getydayfromstr(arg_str));
    }
    else {
        char output[25] = {'\0'};
        arg_year=atoi(argv[1]);
        arg_yday=atoi(argv[2]);
        if(arg_yday<0 || arg_yday>366) {
            printf("Usage: %s doy | yyyy-mm-dd \n",argv[0]);
            return 0; 
        }
        printf("input: %d %d\n",arg_year,arg_yday);
        getymd(arg_year,arg_yday,output);     
        printf("output: %s\n",output);     
    }     

    return 0;
}


