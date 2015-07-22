%*******************************************************************************
%* Copyright (c) 2011 AICIA, BBC, Pace, Panasonic, SIDSA
%* 
%* Permission is hereby granted, free of charge, to any person obtaining a copy
%* of this software and associated documentation files (the "Software"), to deal
%* in the Software without restriction, including without limitation the rights
%* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%* copies of the Software, and to permit persons to whom the Software is
%* furnished to do so, subject to the following conditions:
%*
%* The above copyright notice and this permission notice shall be included in
%* all copies or substantial portions of the Software.
%*
%* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%* THE SOFTWARE.
%* 
%* This notice contains a licence of copyright only and does not grant 
%* (implicitly or otherwise) any patent licence and no permission is given 
%* under this notice with regards to any third party intellectual property 
%* rights that might be used for the implementation of the Software.  
%*
%******************************************************************************
%* Project     : DVB-T2 Common Simulation Platform 
%* URL         : http://dvb-t2-csp.sourceforge.net
%* Date        : $Date$
%* Version     : $Revision$
%* Description : T2_RX_L1DECODE_WR DVBT2 L1 decoding Wrapper
%*               T2_RX_L1DECODE_WR(DVBT2) wrapper for the DVBT2 L1 decoding.
%*  
%*               T2_RX_L1DECODE_WR(DVBT2, FID) specifies the file identifier in FID
%*               where any debug message is sent.
%******************************************************************************

function t2_rx_l1decode_wr(DVBT2, FidLogFile)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_rx_dmap_wr SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
ENABLED  = DVBT2.RX.L1DECODE.ENABLE; % Enable
DI_FNAME = DVBT2.RX.L1DECODE_FDI;    % Input file
DO_FNAME = DVBT2.RX.L1DECODE_FDO;    % Output file
TYPE     = DVBT2.RX.L1DECODE.TYPE;   % Block type
SIM_DIR  = DVBT2.SIM.SIMDIR;    % Simulation directory 
           
%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
global DATA;
    
if ENABLED
  fprintf(FidLogFile,'\tDVBT2-RX-L1DECODE: (%s)\n', TYPE);

  if strcmp(DI_FNAME, '')
    data = DATA;
    
  else
    load(strcat(SIM_DIR, filesep, DI_FNAME), 'data'); % Load input data    
  end  

  switch TYPE
    case 'DVBT2BLCHEAT'              
      data = t2_rx_dvbt2blcheatl1decode(DVBT2, FidLogFile, data);  
    case 'DVBT2BLBASIC'              
      data = t2_rx_dvbt2blbasicl1decode(DVBT2, FidLogFile, data);  
    otherwise     
      error('Unknown L1 decoder type %s', TYPE);
  end

else % If disabled
  fprintf(FidLogFile,'\tDVBT2-RX-L1DECODE: DISABLED\n');
end

%------------------------------------------------------------------------------
% Output saving and formatting
%------------------------------------------------------------------------------
if ENABLED
  if strcmp(DO_FNAME, '')
    DATA = data;
    fprintf(FidLogFile,'\t\tL1 decoder output stored in workspace\n');
  else
    save(strcat(SIM_DIR, filesep, DO_FNAME),'data')
    fprintf(FidLogFile,'\t\tL1 decoder output saved in file: %s\n',DO_FNAME);
  end
end