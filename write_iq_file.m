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
%* Description : Write IQ file 16 bits big-endian
%*               
%******************************************************************************

function write_iq_file(FidLogFile, data, DVBT2)

scale = 2048;

FILENAME = DVBT2.SIM.OUTPUT_IQ_FILENAME;

if strcmp(FILENAME,'') 
    return;
end

if DVBT2.START_T2_FRAME == 0 
    % first frame of the simulation - restart file
    fprintf(FidLogFile,'\t\t  Writing to IQ file (%s): %d bytes\n', FILENAME, length(data)/4);
    outfile = fopen(FILENAME,'wb');
else
    % Append to existing file
    fprintf(FidLogFile,'\t\tAppending to IQ file (%s): %d bytes\n', FILENAME, length(data)/4);
    outfile = fopen(FILENAME,'ab');
end

data = data(:) * scale;
data = [real(data) imag(data)]';
data = data(:);
%andrewm - changed to little endian
fwrite(outfile, data, 'int16','ieee-le');

fclose(outfile);
end
