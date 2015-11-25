//------------------------------------------------------------------------------------------------------------------------------
//
// File:       Controller.m
//
// Abstract:   Cocoa PTP pass-through test application.
//
// Version:    1.0
//
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//             in consideration of your agreement to the following terms, and your use,
//             installation, modification or redistribution of this Apple software
//             constitutes acceptance of these terms.  If you do not agree with these
//             terms, please do not use, install, modify or redistribute this Apple
//             software.
//
//             In consideration of your agreement to abide by the following terms, and
//             subject to these terms, Apple grants you a personal, non - exclusive
//             license, under Apple's copyrights in this original Apple software ( the
//             "Apple Software" ), to use, reproduce, modify and redistribute the Apple
//             Software, with or without modifications, in source and / or binary forms;
//             provided that if you redistribute the Apple Software in its entirety and
//             without modifications, you must retain this notice and the following text
//             and disclaimers in all such redistributions of the Apple Software. Neither
//             the name, trademarks, service marks or logos of Apple Inc. may be used to
//             endorse or promote products derived from the Apple Software without specific
//             prior written permission from Apple.  Except as expressly stated in this
//             notice, no other rights or licenses, express or implied, are granted by
//             Apple herein, including but not limited to any patent rights that may be
//             infringed by your derivative works or by other works in which the Apple
//             Software may be incorporated.
//
//             The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//             WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//             WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//             PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//             ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//             IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//             CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//             SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//             INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//             AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//             UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//             OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2009 Apple Inc. All Rights Reserved.
//
//------------------------------------------------------------------------------------------------------------------------------

#import "PTPProtocolHelpers.h"
#import "Controller.h"

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ Controller

@implementation Controller

@synthesize camera = _camera;

//-------------------------------------------------------------------------------------------------------------------------- log

- (void)log:(NSString*)str
{
    int endPos = [[_logView string] length];

    [_logView setSelectedRange:NSMakeRange(endPos,0)];
    [_logView setEditable:YES];
    [_logView insertText:str];
    [_logView setEditable:NO];
    [_logView display];
}

//----------------------------------------------------------------------------------------------------- dumpData:length:comment:
// This method dumps a buffer in hexadecimal format

- (void)dumpData:(void*)data length:(int)length comment:(NSString*)comment
{
    UInt32	i,
            j;
    UInt8*  p;
    char	fStr[80];
    char*   fStrP;
    NSMutableString*  s = [NSMutableString stringWithFormat:@"\n  %@ [%ld bytes]:\n\n", comment, length];

    p = (UInt8*)data;
    
    for ( i = 0; i < length; i++ )
    {
        if ( (i % 16) == 0 )
        {
            fStrP = fStr;
            fStrP += snprintf( fStrP, 10, "    %4X:", (unsigned int)i );
        }
        if ( (i % 4) == 0 )
            fStrP += snprintf( fStrP, 2, " " );
        fStrP += snprintf( fStrP, 3, "%02X", (UInt8)(*(p+i)) );
        if ( (i % 16) == 15 )
        {
            fStrP += snprintf( fStrP, 2, " " );
            for ( j = i-15; j <= i; j++ )
            {
                if ( *(p+j) < 32 || *(p+j) > 126 )
                    fStrP += snprintf( fStrP, 2, "." );
                else
                    fStrP += snprintf( fStrP, 2, "%c", *(p+j) );
            }
            [s appendFormat:@"%s\n", fStr];
        }
        if ( (i % 256) == 255 )
            [s appendString:@"\n"];
    }
    
    if ( (i % 16) )
    {
        for ( j = (i % 16); j < 16; j ++ )
        {
            fStrP += snprintf( fStrP, 3, "  " );
            if ( (j % 4) == 0 )
                fStrP += snprintf( fStrP, 2, " " );
        }
        fStrP += snprintf( fStrP, 2, " " );
        for ( j = i - (i % 16 ); j < length; j++ )
        {
            if ( *(p+j) < 32 || *(p+j) > 126 )
                fStrP += snprintf( fStrP, 2, "." );
            else
                fStrP += snprintf( fStrP, 2, "%c", *(p+j) );
        }
        for ( j = (i % 16); j < 16; j ++ )
        {
            fStrP += snprintf( fStrP, 2, " " );
        }
        [s appendFormat:@"%s\n", fStr];
    }
    
      [s appendString:@"\n"];
      [self log:s];
}

#pragma mark -
//----------------------------------------------------------------------------------------------- applicationDidFinishLaunching:

- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
	[_logView setFont:[NSFont userFixedPitchFontOfSize:10]];
    _deviceBrowser = [[ICDeviceBrowser alloc] init];
    _deviceBrowser.delegate = self;
    _deviceBrowser.browsedDeviceTypeMask = ICDeviceTypeMaskCamera | ICDeviceLocationTypeMaskLocal;
}

//----------------------------------------------------------------------------- applicationShouldTerminateAfterLastWindowClosed:

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

//---------------------------------------------------------------------------------------------------- applicationWillTerminate:

- (void)applicationWillTerminate: (NSNotification *)notification
{
    self.camera = NULL;
    [_deviceBrowser release];
}

#pragma mark -
#pragma mark ICDeviceBrowser delegate methods
//------------------------------------------------------------------------------------------------------------------------------
// Please refer to the header files in ImageCaptureCore.framework for documentation about the following delegate methods.

//--------------------------------------------------------------------------------------- deviceBrowser:didAddDevice:moreComing:

- (void)deviceBrowser:(ICDeviceBrowser*)browser didAddDevice:(ICDevice*)addedDevice moreComing:(BOOL)moreComing
{
    // use the first PTP camera
    if ( ( self.camera == NULL ) && ( (addedDevice.type & ICDeviceTypeMaskCamera) == ICDeviceTypeCamera ) )
    {
        if ( [addedDevice.capabilities containsObject:ICCameraDeviceCanAcceptPTPCommands] )
        {
            [self log:[NSString stringWithFormat:@"\nFound a PTP camera '%@'.\n", addedDevice.name]];
            
            self.camera           = (ICCameraDevice*)addedDevice;
            self.camera.delegate  = self;
            
            [self log:[NSString stringWithFormat:@"\nOpening a session on '%@'...\n", self.camera.name]];
            [self.camera requestOpenSession];
        }
    }
}

//----------------------------------------------------------------------------------------------- deviceBrowser:didRemoveDevice:

- (void)deviceBrowser:(ICDeviceBrowser*)browser didRemoveDevice:(ICDevice*)removedDevice moreGoing:(BOOL)moreGoing
{
    if ( self.camera == removedDevice )
    {
        [self log:[NSString stringWithFormat:@"\nPTP camera '%@' has been removed.\n", removedDevice.name]];
        self.camera = NULL;
    }
}

#pragma mark -
#pragma mark ICDevice & ICCameraDevice delegate methods
//------------------------------------------------------------------------------------------------------------- didRemoveDevice:

- (void)didRemoveDevice:(ICDevice*)removedDevice
{
    if ( self.camera == removedDevice )
    {
        [self log:[NSString stringWithFormat:@"\nPTP camera '%@' has been removed.\n", removedDevice.name]];
        self.camera = NULL;
    }
}

//---------------------------------------------------------------------------------------------- device:didOpenSessionWithError:

- (void)device:(ICDevice*)device didOpenSessionWithError:(NSError*)error
{
    if ( error )
        [self log:[NSString stringWithFormat:@"\nFailed to open a session on '%@'.\nError:\n", device.name, error]];
    else
        [self log:[NSString stringWithFormat:@"\nSession opened on '%@'.\n", device.name]];
}

//-------------------------------------------------------------------------------------------------------- deviceDidBecomeReady:

- (void)deviceDidBecomeReady:(ICCameraDevice*)camera;
{
    [self log:[NSString stringWithFormat:@"\nPTP camera '%@' is ready.\n", camera.name]];
}

//--------------------------------------------------------------------------------------------- device:didCloseSessionWithError:

- (void)device:(ICDevice*)device didCloseSessionWithError:(NSError*)error
{
    if ( error )
        [self log:[NSString stringWithFormat:@"\nFailed to close a session on '%@'.\nError:\n", device.name, error]];
    else
        [self log:[NSString stringWithFormat:@"\nSession closed on '%@'.\n", device.name]];
}

//---------------------------------------------------------------------------------------------------- device:didEncounterError:

- (void)device:(ICDevice*)device didEncounterError:(NSError*)error
{
    [self log:[NSString stringWithFormat:@"\nPTP camera '%@' encountered an error: \n%@\n", device.name, error]];
}

//--------------------------------------------------------------------------------------------------- device:didReceivePTPEvent:

- (void)cameraDevice:(ICCameraDevice*)camera didReceivePTPEvent:(NSData*)eventData
{
    PTPEvent* event = [[PTPEvent alloc] initWithData:eventData];
    [self log:@"\nReceived a PTP event:"];
    [self log:[event description]];
}

// ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ------------------ÑÑÑÑÑÑÑÑÑÑÑÑÑÑ didSendCommand:data:response:error:contextInfo:
// This delegate method is invoked when "requestSendPTPCommand:..." is completed. Please refer to ICCameraDevice.h file in ImageCaptureCore.framework for more information about how to use the "requestSendPTPCommand:..." method.

 - (void)didSendPTPCommand:(NSData*)command inData:(NSData*)data response:(NSData*)response error:(NSError*)error contextInfo:(void*)contextInfo
 {
    PTPOperationRequest*  ptpRequest  = (PTPOperationRequest*)contextInfo;
    PTPOperationResponse* ptpResponse = NULL;
    
    if ( ptpRequest )
    {
        [self log:@"\nCompleted request:"];
        [self log:[ptpRequest description]];
    }
    
    if ( data )
    {
        [self log:@"\nReceived data:"];
        [self dumpData:(void*)[data bytes] length:(int)[data length] comment:@"inData"];
    }
        
    if ( response )
    {
        ptpResponse = [[PTPOperationResponse alloc] initWithData:response];
        [self log:@"\nReceived response:"];
        [self log:[ptpResponse description]];
    }

    switch ( ptpRequest.operationCode )
    {
        case PTPOperationCodeGetStorageIDs:
            if ( ptpResponse && (ptpResponse.responseCode == PTPResponseCodeOK) && data )
            {
                uint32_t* temp = (uint32_t*)[data bytes];
                
                _storageID = *(++temp);
                [self log:[NSString stringWithFormat:@"\n_storageID: %d", _storageID]];
            }
            break;
        
        case PTPOperationCodeGetNumObjects:
            if ( ptpResponse && (ptpResponse.responseCode == PTPResponseCodeOK) )
            {
                _numObjects = ptpResponse.parameter1;
                [self log:[NSString stringWithFormat:@"\n_numObjects: %d", _numObjects]];
            }
            break;
            
        case PTPOperationCodeGetObjectHandles:
            if ( ptpResponse && (ptpResponse.responseCode == PTPResponseCodeOK) && data )
            {
                uint32_t* temp = (uint32_t*)[data bytes];
                uint32_t  i;
                
                _numObjects = *temp;
                
                if ( _objects )
                    free( _objects );
                    
                _objects = malloc( _numObjects*sizeof(uint32_t) );
                memcpy( _objects, ++temp, _numObjects*sizeof(uint32_t) );
                
                [self log:[NSString stringWithFormat:@"\n_numObjects: %d", _numObjects]];
                for ( i = 0; i < _numObjects; ++i )
                    [self log:[NSString stringWithFormat:@"\n  object %d: 0x%08X", i, _objects[i]]];
            }
            break;
    }
    
    [ptpResponse release];
 }

#pragma mark -
// ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ startStopBrowsing:

- (IBAction)startStopBrowsing:(id)sender
{
    if ( _deviceBrowser.browsing == NO )
    {
        [_deviceBrowser start];
        [self log:@"Looking for a PTP camera...\n"];
        [sender setTitle:@"Stop Browsing"];
    }
    else
    {
        [_deviceBrowser stop];
        [self log:@"Stopped looking for a PTP camera.\n"];
        [sender setTitle:@"Start Browsing"];
    }
}

// ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ getStorageIDs:

- (IBAction)getStorageIDs:(id)sender;
{
    NSData*               commandBuffer = NULL;
    PTPOperationRequest*  request       = [[PTPOperationRequest alloc] init];
    
    request.operationCode       = PTPOperationCodeGetStorageIDs;
    request.numberOfParameters  = 0;
    commandBuffer               = request.commandBuffer;
    
    [self log:@"\nSending PTP request:"];
    [self log:[request description]];

    [self.camera requestSendPTPCommand:commandBuffer outData:NULL sendCommandDelegate:self didSendCommandSelector:@selector(didSendPTPCommand:inData:response:error:contextInfo:) contextInfo:request];
    
    // Note: request is released in the 'didSendPTPCommand:inData:response:error:contextInfo:' method
}

// ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ getNumObjects:

- (IBAction)getNumObjects:(id)sender;
{
    if ( _storageID )
    {
        NSData*               commandBuffer = NULL;
        PTPOperationRequest*  request       = [[PTPOperationRequest alloc] init];
        
        request.operationCode       = PTPOperationCodeGetNumObjects;
        request.numberOfParameters  = 3;
        request.parameter1          = _storageID;
        request.parameter2          = 0;
        request.parameter3          = 0;
        commandBuffer               = request.commandBuffer;
        
        [self log:@"\nSending PTP request:"];
        [self log:[request description]];

        [self.camera requestSendPTPCommand:commandBuffer outData:NULL sendCommandDelegate:self didSendCommandSelector:@selector(didSendPTPCommand:inData:response:error:contextInfo:) contextInfo:request];
        
        // Note: request is released in the 'didSendPTPCommand:inData:response:error:contextInfo:' method
    }
}

// ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ getObjectHandles:

- (IBAction)getObjectHandles:(id)sender;
{
    if ( _numObjects )
    {
        NSData*               commandBuffer = NULL;
        PTPOperationRequest*  request       = [[PTPOperationRequest alloc] init];
        
        request.operationCode       = PTPOperationCodeGetObjectHandles;
        request.numberOfParameters  = 3;
        request.parameter1          = _storageID;
        request.parameter2          = 0;
        request.parameter3          = 0;
        commandBuffer               = request.commandBuffer;
        
        [self log:@"\nSending PTP request:"];
        [self log:[request description]];

        [self.camera requestSendPTPCommand:commandBuffer outData:NULL sendCommandDelegate:self didSendCommandSelector:@selector(didSendPTPCommand:inData:response:error:contextInfo:) contextInfo:request];
        
        // Note: request is released in the 'didSendPTPCommand:inData:response:error:contextInfo:' method
    }
}

// ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ getPartialObject:

- (IBAction)getPartialObject:(id)sender;
{
    if ( _numObjects && _objects )
    {
        NSData*               commandBuffer = NULL;
        PTPOperationRequest*  request       = [[PTPOperationRequest alloc] init];
        
        request.operationCode       = PTPOperationCodeGetPartialObject;
        request.numberOfParameters  = 3;
        request.parameter1          = _objects[_numObjects-1];  // last object
        request.parameter2          = 0;
        request.parameter3          = [_dataSize intValue];
        commandBuffer               = request.commandBuffer;
        
        [self log:@"\nSending PTP request:"];
        [self log:[request description]];

        [self.camera requestSendPTPCommand:commandBuffer outData:NULL sendCommandDelegate:self didSendCommandSelector:@selector(didSendPTPCommand:inData:response:error:contextInfo:) contextInfo:request];
        
        // Note: request is released in the 'didSendPTPCommand:inData:response:error:contextInfo:' method
    }
}

//------------------------------------------------------------------------------------------------------------------------------

@end

//------------------------------------------------------------------------------------------------------------------------------
