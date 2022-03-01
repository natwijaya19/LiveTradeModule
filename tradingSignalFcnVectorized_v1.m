% Function definition
function tradingSignalTT = tradingSignalFcnVectorized_v1 (paramsInput, dataInput)


% Transfer
x = paramsInput ;

% Transfer input values to each variables. All variables are converted from
% ineteger value in optimization adjusted to the suitable unit
volumeMAtreshold = x(:,1)/100 ; % input #1 
volumeMAlookback = x(:,2) ; % input #2
valueThreshold = x(:,3)*10^9 ; % input #3 in Rp billion
valueLookback = x(:,4) ; % input #4
volumeValueBufferDays = x(:,5) ; % input #5
priceRetLowCloseThresh = x(:,6)/100 ; % input #6
priceMAThreshold = x(:,7)/100 ; % input #7
priceMAlookback = x(:,8) ; % input #8
priceVolumeValueBufferDays = x(9) ; % input #9
cutlossLookback = x(:,10) ; % input #10
cutlosspct = x(:,11)/100 ; % input #11 


% Signal from higher volume than historical volume MA
% m = matfile ("pricevolumedata.mat") ;
% m = load ("pricevolumedata.mat");
volumeTT = dataInput.volumeTT ;
% volumeMAtreshold = 1.5 ; % input variable
% volumeMAlookback = 100 ; % input variable
volumeMA = movmean (volumeTT.Variables, [volumeMAlookback 0], 1, 'omitnan');
volumeSignal = volumeTT.Variables > (volumeMA *volumeMAtreshold);
clear volumeMA

% Signal value threshold
closepriceTT = dataInput.closepriceTT ;
% valueThreshold = 2*10^9 ; % input variable
% valueLookback = 5 ; % input variable
transactionValue = closepriceTT.Variables .* volumeTT.Variables ;
valueMA = movmean (transactionValue, [valueLookback 0], 1, 'omitnan');
valueSignal = valueMA > valueThreshold ;
clear valueMA transactionValue

% Volume value buffer days
% volumeValueBufferDays = 5 ; % input variable
volumeValue = volumeSignal .* valueSignal;
volumeValueBufferSignal = movmax(volumeValue,[volumeValueBufferDays, 0], 1, 'omitnan');
clear volumeValue valueSignal volumeSignal

% Signal price return from low to close 
% priceRetLowCloseThresh = 0.1 ; % input variable
lowpriceTT = dataInput.lowpriceTT ;
priceRetLowClose = closepriceTT.Variables ./ lowpriceTT.Variables -1 ;
priceRetLowCloseSignal = priceRetLowClose > priceRetLowCloseThresh;
% clear lowpriceTT priceRetLowClose

% price MA
% priceMAThreshold = 1.1 ; % input variable
% priceMAlookback = 20 ; % input variable
priceMA = movmean (closepriceTT.Variables,[priceMAlookback, 0], 1, 'omitnan');
priceMASignal = closepriceTT.Variables > priceMA .* priceMAThreshold;
% clear priceMA

% price volume value buffer days
% priceVolumeValueBufferDays = 5; % input variable
priceVolumeValueBuffer =  volumeValueBufferSignal .* priceRetLowCloseSignal .* priceMASignal;
priceVolumeValueBufferSignal = movmax(priceVolumeValueBuffer,[priceVolumeValueBufferDays, 0], 1, 'omitnan');
% clear volumeValueBufferSignal priceRetLowCloseSignal priceMASignal

% cut loss signal
% cutlossLookback = 5; % input variable
% cutlosspct = 5/100; % input variable
highpriceTT = dataInput.highpriceTT ;
lastMaxHighprice = movmax(highpriceTT.Variables ,[cutlossLookback, 0], 1, 'omitnan');
LastHightoCLose = (closepriceTT.Variables ./ lastMaxHighprice) -1 ;
cutlossSignal = LastHightoCLose > (-cutlosspct);
% close lastMaxHighprice LastHightoCLose

% Pre final signal (not yet 1 step lag shifted to avoid look ahead bias)
preFinalSignal = priceVolumeValueBufferSignal .* cutlossSignal;
% clear priceVolumeValueBufferSignal cutlossSignal

% Warming up or initialization days 
lookbackArray = [volumeMAlookback, priceMAlookback, cutlossLookback] ;
warmingUpsteps = max(lookbackArray) ;
preFinalSignal (1:warmingUpsteps, :) = 0 ;

% Lag shifted 1 step forward to remove look ahead bias
finalSignal = preFinalSignal;
finalSignal (2:end,:) = preFinalSignal(1:end-1, :);
finalSignal (1,:) = 0 ;
finalSignal (isnan(finalSignal)) = 0 ;
% clear preFinalSignal

% copy to end output signal variable
tradingSignal = finalSignal ;
% clear finalSignal

% Save to matfile
tradingSignalTT = dataInput.closepriceTT ;
tradingSignalTT.Variables = tradingSignal ;

sym = tradingSignalTT.Properties.VariableNames ;
sym = eraseBetween (sym, 5,10) ;
tradingSignalTT.Properties.VariableNames  = sym ;


% Remove intermediary variables
clearvars -except tradingSignalTT
End function
end
