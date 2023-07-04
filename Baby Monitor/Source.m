clearvars;
clc;
myDir = pwd; %gets directory
filePattern = fullfile(myDir, '*.avi*');
myFiles = dir(filePattern);
%myFiles = dir(fullfile(myDir,'vid*.avi')); %gets all txt files in struct
for vid_num=1:length(myFiles)
    %v = VideoReader("S_Rel_AVI.avi");
    v = VideoReader(eval(sprintf('''vid%d.avi''', vid_num)));
    %FFT length.
    fft_len = 512; %frequency resolution
    %Video rate is 30 frames per second.
    vid_rate = 30;
    %Get number of frames in the video file.
    vid_len = v.NumFrames;
    %Generate arrays of zeros.
    aa = zeros(1,fft_len+1);
    ab = zeros(1,fft_len);
    %Loop through every frame and calculate a sum for each frame.
    for ii = 1:fft_len+1
        video1 = read(v,ii); %read(video, index)
        video1bw = rgb2gray(video1);
        %frame_val = sum(sum(video1bw));
        frame_val = sum(video1bw(:) > 200); %200 is threshold for noise.
        aa(ii) = frame_val;
    end
    %Loop through and calculate the difference between frames.
    for ii = 1:fft_len
        video1 = aa(ii);
        video2 = aa(ii+1);
        ab(ii) = video1 - video2;
    end

    %Calculate x-axis values -15Hz to 15Hz.
    dW = vid_rate/fft_len; %
    W = 1 : 1 : fft_len;
    W = W - .5*fft_len;
    W = W*dW;
    %FFT of difference calculation.
    X1 = abs(fftshift(fft(ab, fft_len)));
    %Create low pass filter with cutoff of 1.5Hz.
    B = firpm(100, [0 .09 .1 1], [1 1 0 0]);
    [H,WD]=freqz(B,1,1024,'whole');
    %Filter difference data.
    filt_out = filter(B, 1, ab); 
    X2 = abs(fftshift(fft(filt_out, fft_len)));
    figure(1);
    plot(aa);
    xlabel('Num of Frames');
    ylabel('Count of pixels value > 200');
    grid on;
    hold on;
    figure(2);
    plot(ab);
    xlabel('Frequency');
    %ylabel('Normalized pixels count');
    grid on;
    hold on;
    
    %figure();
    %plot(W, X1);
    %ylim([0 max(X1)]);
    %xlabel('Frequncy/Hz');
    %grid on;
    %grid minor;
    %set(gca,'xtick',[-15:1:15]);
    %ylim([0 80000])
    %figure();
    %plot((WD-pi)/pi, abs(fftshift(H)));
    %title('Low Pass Filter w/ 100th order')
    
    figure(vid_num);
    plot(W, X2);
    ylim([0 max(X1)]);
    xlabel('Frequncy/Hz');
    grid on;
    grid minor;
    set(gca,'xtick',[-15:1:15]);
    ylim([0 80000]);
    trigger = max(X2);
    if(trigger) > 8000;
        disp(' Breathing Detected.');
        fp = fopen(sprintf('breath%d.txt', vid_num),'w');
        fprintf(fp, '1');
        fclose(fp);
    else
        disp('No Breathing Detected!');
        fp = fopen(sprintf('breath%d.txt', vid_num),'w');
        fprintf(fp, '0');
        fclose(fp);
    end
end