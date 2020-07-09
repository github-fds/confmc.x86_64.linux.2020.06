#ifndef CONAPI_H
#define CONAPI_H
//------------------------------------------------------------------------------
// Copyright (c) 2018-2019 by Future Design Systems.
// All right reserved.
// http://www.future-ds.com
//------------------------------------------------------------------------------
/// @file conapi.h
/// @brief This header file contains function prototypes for CON-FMC PCB V1.1.
/// @author Ando Ki
/// @data 20/5/2019
//------------------------------------------------------------------------------
#include "conapi_int.h"

#if defined(_MSC_VER)
    #define CONFMC_API
#else
    #if (defined(_WIN32)||defined(_WIN64))
       #ifdef BUILDING_DLL
          #define CONFMC_API __declspec(dllexport)
       #else
          #ifdef BUILDING_STATIC
             #define CONFMC_API
          #else
             #define CONFMC_API __declspec(dllimport)
          #endif
       #endif
    #else
       #define CONFMC_API
    #endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

//------------------------------------------------------------------------------
CONFMC_API con_Handle_t conInit ( unsigned int con_cid
                            , unsigned int con_mode
                            , unsigned int conapi_log_level );
CONFMC_API int conRelease ( con_Handle_t con_handle );
CONFMC_API int conCmdWrite ( con_Handle_t  con_handle
                       , void         *pBuffer
                       , unsigned int  nNumberOfItemsToWrite
                       , unsigned int *pNumberOfItemsWritten
                       , unsigned int  transactor );
CONFMC_API int conDataWrite( con_Handle_t  con_handle
                       , void         *pBuffer
                       , unsigned int  nNumberOfItemsToWrite
                       , unsigned int *pNumberOfItemsWritten
                       , unsigned int  transactor );
CONFMC_API int conDataRead ( con_Handle_t  con_handle
                       , void         *pBuffer
                       , unsigned int  nNumberOfItemsToRead 
                       , unsigned int *pNumberOfItemsRead
                       , unsigned int  transactor );
CONFMC_API int conStreamWrite( con_Handle_t  con_handle
                         , void         *pBuffer
                         , unsigned int  nNumberOfItemsToWrite
                         , unsigned int *pNumberOfItemsWritten
                         , unsigned int  zlp );
CONFMC_API int conStreamRead ( con_Handle_t  con_handle
                         , void         *pBuffer
                         , unsigned int  nNumberOfItemsToRead 
                         , unsigned int *pNumberOfItemsRead );
CONFMC_API int conZlpWrite ( con_Handle_t  con_handle );
CONFMC_API int conGetUsbInfo ( con_Handle_t     con_handle
                         , struct _usb *pInfo );
CONFMC_API int conGetBoardInfo ( con_Handle_t     con_handle
                           , con_BoardInfo_t *pInfo
                           , unsigned int     length
                           , unsigned int     crc_check );
CONFMC_API int conSetBoardInfo ( con_Handle_t     con_handle
                           , con_BoardInfo_t *pInfo
                           , unsigned int     length
                           , unsigned int     crc_check );
CONFMC_API int conGetMasterInfo ( con_Handle_t      con_handle
                            , con_MasterInfo_t *pInfo );
CONFMC_API int conGetFx3Info ( con_Handle_t   con_handle
                         , con_Fx3Info_t *pVersion );
CONFMC_API int conReset   ( con_Handle_t con_handle
                      , unsigned int duration );
CONFMC_API int conSetMode ( con_Handle_t con_handle
                      , unsigned int con_mode );
CONFMC_API int conGetCid  ( con_Handle_t con_handle );
CONFMC_API unsigned int conGetVersionApi( void );
CONFMC_API unsigned int conGetVersionLibusb( void );
CONFMC_API const int conGetErrorLibusb( void );
CONFMC_API const int conGetErrorConapi( void );
CONFMC_API const char *conErrorMsgConapi( int error );
CONFMC_API const char *conErrorMsgLibusb( int error );

#ifdef __cplusplus
}
#endif

//------------------------------------------------------------------------------
// __declspec(dllexport) means that the symbol should be exported from a DLL
// (if it is indeed made part of a DLL).
// It is used when compiling the code that goes into the DLL.
// __declspec(dllexport) tells the linker that you want this object to be made
// available for other DLL's to import. It is used when creating a DLL
// that others can link to.
// 
// __declspec(dllimport) means that the symbol will be imported from a DLL.
// It is used when compiling the code that uses the DLL.
// __declspec(dllimport) imports the implementation from a DLL so your
// application can use it.
//------------------------------------------------------------------------------
// Revision history
//
// 2019.05.20: _MSC_VER added
// 2019.02.10: Updated
// 2018.05.18: conZlpWrite() added
// 2018.03.20: Started by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
#endif //CONAPI_H
