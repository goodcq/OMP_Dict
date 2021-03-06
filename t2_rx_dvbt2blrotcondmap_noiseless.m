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
%* Description : T2_RX_DVBT2BLROTCONDMAP DVBT2 Demapper
%*               DATAOUT = T2_RX_DVBT2BLROTCONDMAP(DVBT2, FID, DATAIN) demaps DATAIN
%*               and stores de result in DATAOUT following the configuration 
%*               parameters of the DVBT2 structure. FID specifies the file
%*               identifier where any debug message is sent.
%******************************************************************************

function DataOut = t2_rx_dvbt2blrotcondmap(DVBT2, FidLogFile, DataRx, DataTx)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 4,
  otherwise,
    error('t2_rx_dvbt2blrotcondmap SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------

PLP = DVBT2.RX_PLP; % PLP to decode in the receiver

SNR           = DVBT2.CH.NOISE.SNR;     % Signal to noise ratio (dB)
CONSTEL       = DVBT2.PLP(PLP).CONSTELLATION;    % DVBT2 constellation
FECLEN_BITS   = DVBT2.PLP(PLP).FECLEN;           % FEC block size (16200 or 64800)
BITS_PER_CELL = DVBT2.STANDARD.PLP(PLP).MAP.V;   % constellation order
GA            = DVBT2.RX.ROTCON.GA;     % Genie-Aided Demapper

CELLS_PER_FEC_BLOCK = FECLEN_BITS / BITS_PER_CELL;

EN_PAUSES    = DVBT2.SIM.EN_PAUSES;       % Pause enable
EN_FIGS      = DVBT2.SIM.EN_FIGS;         % Figure enable
SAVE_FIGS    = DVBT2.SIM.SAVE_FIGS;       % Enable figure saving
SIM_DIR      = DVBT2.SIM.SIMDIR;          % Saving directory
CLOSE_FIGS   = DVBT2.SIM.CLOSE_FIGS;      % Close figure after plotting

BYPASS       = DVBT2.PLP(PLP).ROTCON_BYPASS;          % Bypass rotated constellations
EN_CONST_A   = DVBT2.RX.ROTCON.EN_CONST_A;   % Enable post-derotation constellation plot
CONSTA_FNAME = DVBT2.RX.ROTCON.CONSTA_FNAME; % Figure file name if saved

C_POINTS  =  DVBT2.STANDARD.PLP(PLP).MAP.C_POINTS;
C         =  DVBT2.STANDARD.PLP(PLP).MAP.C;
V         =  DVBT2.STANDARD.PLP(PLP).MAP.V;

minLogMetric    = -100;

% STATE INITIALISATION
global DVBT2_STATE
if DVBT2.START_T2_FRAME == 0
    DVBT2_STATE.RX.ROTCONDMAP.UNUSED_TX_DATA = [];
end


%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

if GA && isempty(DataTx)
  error('The mapper output must be saved if Genie-Aided demapper is used');  
end

switch CONSTEL
  case 'QPSK'
      ROTATION_ANGLE_DEGREES = 29.0;
  case '16-QAM'
      ROTATION_ANGLE_DEGREES = 16.8;
  case '64-QAM'
      ROTATION_ANGLE_DEGREES = 8.6;
  case '256-QAM'
      ROTATION_ANGLE_DEGREES = atand(1/16);
end
ROTATION_ANGLE_RADIANS = 2*pi*ROTATION_ANGLE_DEGREES/360;

if SNR>40
  nsr=1e-4;
else
  nsr = 10^(-SNR/10);
end

if (BYPASS == 0)
  u1 = reshape(real(DataRx.data), 1, []);

  % undo imag shift
  u2 = reshape(imag(DataRx.data), CELLS_PER_FEC_BLOCK, []);
  u2 = u2([2:end 1], :);
  u2 = reshape(u2, 1, []);
  data = u1 + 1j*u2;
  
  noiseEst = estimateNoise (FidLogFile, data, C, V, BYPASS, ROTATION_ANGLE_RADIANS);
  if ~GA; nsr = noiseEst; end %Use the simulated SNR if doing GA, otherwise use the estimated value

  u1_h_est = DataRx.h_est;
  u1_csi = abs(u1_h_est).^2;
  u1_variance = single(nsr ./ u1_csi')/2;

  u2_h_est = reshape(DataRx.h_est, CELLS_PER_FEC_BLOCK, []);
  u2_h_est = u2_h_est([2:end 1], :);
  u2_h_est = reshape(u2_h_est, 1, []);
  u2_csi = abs(u2_h_est).^2;
  u2_variance = single(nsr ./ u2_csi')/2;
else
  noiseEst = estimateNoise (FidLogFile, DataRx.data, C, V, BYPASS);
  if ~GA; nsr = noiseEst; end %Use the simulated SNR if doing GA, otherwise use the estimated value
  
  u1_h_est = DataRx.h_est;
  u1_csi = abs(u1_h_est).^2;
  u1_variance = single(nsr ./ u1_csi')/2;

  u2_h_est = DataRx.h_est;
  u2_csi = abs(u2_h_est).^2;
  u2_variance = single(nsr ./ u2_csi')/2;

  data = DataRx.data;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ideal sent points (_already_ normalised)
s = C_POINTS;

if (BYPASS == 0)
  % apply rotation
  rotation = cos(ROTATION_ANGLE_RADIANS) + j * sin (ROTATION_ANGLE_RADIANS);
  % rotate to match

  s = s .* rotation;
end

data = reshape(data, CELLS_PER_FEC_BLOCK, []); % one column per FEC block
u1_variance = reshape(u1_variance, CELLS_PER_FEC_BLOCK, []); % one column per FEC block
u2_variance = reshape(u2_variance, CELLS_PER_FEC_BLOCK, []); % one column per FEC block
if GA
    DataTx = reshape(DataTx.data{PLP}, CELLS_PER_FEC_BLOCK, []); % one column per FEC block
    DataTx = [DVBT2_STATE.RX.ROTCONDMAP.UNUSED_TX_DATA DataTx]; % prepend unused data from last time
end

DataOut = zeros(numel(data), BITS_PER_CELL);

%NB non complex conjugate transpose
%r = data.'; % column vector
numFECBlocks = size(data, 2);
fprintf(FidLogFile,'\t\tProcessing %d FEC blocks..',numFECBlocks);
for fecBlockIdx = 1:numFECBlocks
    if mod(fecBlockIdx,10)==0; fprintf(FidLogFile,'%d ',fecBlockIdx); end
    r = data(:,fecBlockIdx);
    block_u1_var = u1_variance(:,fecBlockIdx);
    block_u2_var = u2_variance(:,fecBlockIdx);

    %allocate memory for metrics
    metrics = single(zeros(length(r), length(s)));
    for symbol = 1:length(s)
       metrics(:,symbol) = ...
                      exp (                                                                    ...
                             - (   1./(2.*block_u1_var) .* ( ( real(r) - real(s(symbol)) ) .^2 )   ) ...
                             - (   1./(2.*block_u2_var) .* ( ( imag(r) - imag(s(symbol)) ) .^2 )   ) ...
                          );
    end
    
    %Set minimum metric to prevent Inf LLRs - now removed to avoid very
    %slow calculations
%     metrics(metrics==0)=1e-45;
    
    % go through and calculate metric for each bit
    symbol_values = 0 : (2^BITS_PER_CELL-1);
    binary_symbol_values = de2bi(symbol_values,'left-msb')';

    %allocate memory for bit metrics
    metrics_for_each_bit_being_zero = single(zeros(length(r), BITS_PER_CELL));

    if GA % Genie-Aided demapper
      % Tx data  
      txBlock = DataTx(:, fecBlockIdx);
      txDataBin = de2bi(txBlock,BITS_PER_CELL,'left-msb');

      % Calculate metric for each bit knowing the a priori probability 
      for bit = 1:BITS_PER_CELL
        txDataBinAux = txDataBin;
        txDataBinAux(:,bit) = 0;
        pb0 = bi2de(txDataBinAux,'left-msb');
        txDataBinAux(:,bit) = 1;
        pb1 = bi2de(txDataBinAux,'left-msb');

        metricsZeros = zeros(length(pb0),1);
        metricsOnes = zeros(length(pb1),1);  
        for idx = 1:length(pb0)
          metricsZeros(idx) = metrics(idx,pb0(idx)+1);
          metricsOnes(idx)  = metrics(idx,pb1(idx)+1);
        end

        metrics_for_each_bit_being_zero(:,bit) = log(metricsZeros) - log(metricsOnes);
      end

    else % Non-Iterative demapper
      for bit = 1:BITS_PER_CELL
        ones_cols = binary_symbol_values(bit,:);
        %add one for column indexing (and conveniently we can then remove 0's to weed
        %out columns we want)
        ones_cols = ones_cols .* (symbol_values+1);
        ones_cols = ones_cols(ones_cols ~= 0);

        zeros_cols = ~binary_symbol_values(bit,:);
        %add one for column indexing (and conveniently we can then remove 0's to weed
        %out columns we want)
        zeros_cols = zeros_cols .* (symbol_values+1);
        zeros_cols = zeros_cols(zeros_cols ~= 0);

%         metrics_for_each_bit_being_zero(:,bit) = log( sum(metrics(:,zeros_cols),2) ) - log( sum(metrics(:,ones_cols),2) );

        %Separate out min metrics - calculation of logs of very small
        %numbers is very slow and may have a memory leak; also need to
        %avoid Inf LLRs
        logSumMetricsZeros = sum(metrics(:,zeros_cols),2); %It's not the log yet!
        minMetrics = logSumMetricsZeros==0;
        logSumMetricsZeros (minMetrics) = minLogMetric;
        logSumMetricsZeros (~minMetrics) = log(logSumMetricsZeros(~minMetrics));

        logSumMetricsOnes = sum(metrics(:,ones_cols),2);
        minMetrics = logSumMetricsOnes==0;
        logSumMetricsOnes (minMetrics) = minLogMetric;
        logSumMetricsOnes (~minMetrics) = log(logSumMetricsOnes(~minMetrics));

        metrics_for_each_bit_being_zero(:,bit) = logSumMetricsZeros - logSumMetricsOnes;        
      end
    end
    DataOut((fecBlockIdx-1)*CELLS_PER_FEC_BLOCK+1:fecBlockIdx*CELLS_PER_FEC_BLOCK, :) = metrics_for_each_bit_being_zero;
end
fprintf(FidLogFile,'\n');

clear minMetrics logSumMetricsZeros logSumMetricsOnes metrics_for_each_bit_being_zero

if GA
    DVBT2_STATE.RX.ROTCONDMAP.UNUSED_TX_DATA = DataTx(:,numFECBlocks+1:end);
end

if (BYPASS == 0)
 fprintf(FidLogFile,'\t\tConstellation rotation: %f degrees rotation angle\n',... 
        ROTATION_ANGLE_DEGREES);
      
  if EN_FIGS && EN_CONST_A
    figure;
    plot(data, '.')
    title('u1 vs u2 after undoing cyclic Q shift');
    grid;

    if SAVE_FIGS
      fName = sprintf('%s%s', SIM_DIR, CONSTA_FNAME);
      hgsave(fName);
    end

    if EN_PAUSES
      pause;
    end

    if CLOSE_FIGS
      close;
    end
  end
else
    fprintf(FidLogFile,'\t\tConstellation rotation: bypassed\n');
end

if GA
  fprintf(FidLogFile,'\t\tGenie-Aided demapper\n');
end

%DataOut = double(metrics_for_each_bit_being_zero).';
DataOut = DataOut.';

end

function noiseEst = estimateNoise (FidLogFile, data, C, V, BYPASS, ROTATION_ANGLE_RADIANS)
% Derotate and do 1-D demap to estimate noise on data
if (BYPASS == 0)
    derot=data*(cos(ROTATION_ANGLE_RADIANS)-1j*sin(ROTATION_ANGLE_RADIANS))*C;
else
    derot=data*C;
end
switch V
    case 1              % BPSK - included for completeness!
        C_DEC = 0;
    case 2              % QPSK
        C_DEC = 0;
    case 4              % 16-QAM
        C_DEC = [0 2];
    case 6              % 64-QAM
        C_DEC    = [0 4 2];
    case 8              % 256-QAM
        C_DEC = [0 8 4 2];
end
demap=zeros(V,length(derot));
demap(1,:)=real(derot) - C_DEC(1);
demap(2,:)=imag(derot) - C_DEC(1);
for k=2:length(C_DEC)
    demap(2*k-1,:) = abs(demap(2*(k-1)-1,:)) - C_DEC(k);
    demap(2*k,:)   = abs(demap(2*(k-1),:))   - C_DEC(k);
end
if V==1
    reals=abs(demap(1,:))-1;
    imags=abs(demap(2,:));
else
    reals=abs(demap(V-1,:))-1;
    imags=abs(demap(V,:))-1;
end
noiseEst=mean(reals.^2 + imags.^2)/C^2;
fprintf(FidLogFile,'\t\tEstimated SNR of data: %.2f dB\n', -10*log10(noiseEst));

end