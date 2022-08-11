function frameArray = assignment3_2017

MAX_FRAMES = 600; % you ca n change this and consider increasing it.
RESOLUTION = 1024; % you can change this and consider increasing it.
DURATION = 100; % Duration of video -- you can change this if you want.

% Colors
MAX_DEPTH = 8192; % you will probably need to increase this.
CMAP=colormap( [ hot(1024); flipud(hot(1024)); hot(1024); flipud(hot(1024));hot(1024); flipud(hot(1024)); hot(1024); flipud(hot(1024)) ] ); %change the colormap as you want.

WRITE_VIDEO_TO_FILE = true; % change this as you like (true/false)
DO_IN_PARALLEL = true; %change this as you like (true/false)

if DO_IN_PARALLEL
    startClusterIfNeeded
end

if WRITE_VIDEO_TO_FILE
    openVideoFile
end
 
if DO_IN_PARALLEL || ~WRITE_VIDEO_TO_FILE 
    %preallocate struct array
    %frameArray=struct('cdata',cell(1,MAX_FRAMES),'colormap',cell(1,MAX_FRAMES));
end
 
% the path "around" the mandelbrot set, associating centres of frames
%     with zoom (magnification) levels.  

%            index                 centre      number of times to zoom in by 2
PATH_POINTS =[0,     -0.5000000000+0.000000000i,      -6.0;
              20,    -0.5000000000+0.000000000i,      -1.0;
              25,     -0.7500000000+0.000000000i,      0.0;
              30,    -0.7500000000+0.000000000i,       1.0;
              40,    -1.2500000000+0.000000000i,       1.0;
              45,     0.2500000000+0.000000000i,       1.0;
              50,    -0.7500000000+0.000000000i,      -1.0;
              60,    -0.7500000000+0.000000000i,       2.0;
              70,    -0.7544376726-0.05511583157i,     3.0;
              140,   -0.7544376726-0.05511583157i,     19.0;
              150,   -0.7544376726-0.05511583157i,     12.0;
              160,   -0.7547035026-0.05522701330i,     12.0;
              190,   -0.7547035026-0.05522701330i,     24.0;
              220,   -0.7547035026-0.05522701330i,     5.0;
              240,   -0.7774835155-0.13665492980i,     5.0;
              300,   -0.7774835155-0.13665492980i,     21.0;
              330,   -0.7774835155-0.13665492980i,     7.0;
              340,   -0.7823772226-0.13777518240i,     7.0;
              380,   -0.7823772226-0.13777518240i,     24.0;
              410,   -0.7823772226-0.13777518240i,     34.0;
              440,   -0.7823772226-0.13777518240i,     7.0;
              460,   -0.7809747467-0.1287190513i,      7.0;
              500,   -0.7809747467-0.1287190513i,      28.0;
              580,   -0.7809747467-0.1287190513i,      2.0;
              610,   -0.7500000000+0.000000000i,       1.0;
              615,   -0.7500000000+0.000000000i,       0.0;
              660,   -0.5000000000+0.000000000i,      -6.0];



SIZE_0 = 1.5; % the "size" from the centre of a frame with no zooming.

% scale indexes to number of frames.
scaledIndexArray = PATH_POINTS(:, 1).*((MAX_FRAMES-1)/PATH_POINTS(end, 1));

% interpolate centres and zoom levels.
interpArray = interp1(scaledIndexArray, PATH_POINTS(:, 2:end), 0:(MAX_FRAMES-1), 'pchip');

zoomArray = interpArray(:,2); % zoom level of each frame

% ***** modify the below line to consider zoom levels.
sizeArray = SIZE_0 * ones(MAX_FRAMES,1); % size from centre of each frame.
sizeArray = SIZE_0 * 2.^-zoomArray;

centreArray = interpArray(:,1);  % centre of each frame

iterateHandle = @iterate;

tic % begin timing
if DO_IN_PARALLEL
    parfor frameNum = 1:MAX_FRAMES
        %evaluate function iterate with handle iterateHandle
        frameArray(frameNum) = feval(iterateHandle, frameNum);
    end
else
    for frameNum = 1:MAX_FRAMES
        if WRITE_VIDEO_TO_FILE
            %frame has already been written in this case
            iterate(frameNum);
        else
            frameArray(frameNum) = iterate(frameNum);
        end
    end
end

if WRITE_VIDEO_TO_FILE
    if DO_IN_PARALLEL
        writeVideo(vidObj, frameArray);
    end
    close(vidObj);
    toc %end timing
else
    toc %end timing
    %clf;
    set(gcf, 'Position', [100, 100, RESOLUTION + 10, RESOLUTION + 10]);
    axis off;
    shg; % bring the figure to the top to be seen.
    movie(gcf, frameArray, 1, MAX_FRAMES/DURATION, [5, 5, 0, 0]);
end

    function frame = iterate (frameNum)

        centreX = real(centreArray(frameNum)); 
        centreY = imag(centreArray(frameNum)); 
        size = sizeArray(frameNum); 
        x = linspace(centreX - size, centreX + size, RESOLUTION);
        %you can modify the aspect ratio if you want.
        y = linspace(centreY - size, centreY + size, RESOLUTION);
        
        % the below might work okay unless you want to further optimize
        % Create the two-dimensional complex grid using meshgrid
        [X,Y] = meshgrid(x,y);
        z0 = X + 1i*Y;
        
        % Initialize the iterates and counts arrays.
        z = z0;
        
        % needed for mex, assumedly to make z elements separate
        %in memory from z0 elements.
        z(1,1) = z0(1,1); 
        
        % make c of type uint16 (unsigned 16-bit integer)
        c = zeros(RESOLUTION, RESOLUTION, 'uint16');
        
        % Here is the Mandelbrot iteration.
        c(abs(z) < 2) = 1;
        
        % below line turns warning off for MATLAB R2015b and similar
        %   releases of MATLAB.  Those releases have a bug causing a 
        %   warning for mex invocations like ours.  
        % warning( 'off', 'MATLAB:lang:badlyScopedReturnValue' );

        depth = MAX_DEPTH; % you can make depth dynamic if you want.
        
        for k = 2:depth
           [z,c] = mandelbrot_step(z,c,z0,k);
            % mandelbrot_step is a c-mex file that does one step of:
            %  z = z.^2 + z0;
            %  c(abs(z) < 2) = k;
            
            
        end
        
        % create an image from c and then convert to frame.  Use CMAP
        frame = im2frame(ind2rgb(c, CMAP));
        if WRITE_VIDEO_TO_FILE && ~DO_IN_PARALLEL
            writeVideo(vidObj, frame);
        end
        
        disp(['frame=' num2str(frameNum)]);
    end

    function startClusterIfNeeded
        myCluster = parcluster('local');
        if isempty(myCluster.Jobs) || ~strcmp(myCluster.Jobs(1).State, 'running')
            PHYSICAL_CORES = feature('numCores');
            
            % "hyperthreads" per physical core
            LOGICAL_PER_PHYSICAL = 2; %valid for the i7 on Craig's desktop
            
            % you can change the NUM_WORKERS calculation below if you want.
            NUM_WORKERS = (LOGICAL_PER_PHYSICAL + 1) * PHYSICAL_CORES;
            myCluster.NumWorkers = NUM_WORKERS;
            saveProfile(myCluster);
            disp('This may take a while when needed!')
            parpool(NUM_WORKERS);
        end
    end

    function openVideoFile
        % create video object
        vidObj = VideoWriter('assignment3');
        %vidObj.Quality = 100; % or consider changing
        vidObj.FrameRate = MAX_FRAMES/DURATION;
        open(vidObj);
    end

end

% *Look at the mandelbrot_step.c file and compare with the mandelbrot_step.m file. What do you
% think is the primary optimization that file mandelbrot_step.c leverages? [5 points]
%
% The primary optimization that file mandelbrot_step.c leverages is the
% speedup of the code execution.
% - mandelbrot_step.c: Most of the time spend to update the two array z and
% kz by writing the code in C and creating as a Matlab executable file or
% would help to make this computation faster.
% - Help us to use parallel DO_IN_PARALLEL which speeds up.
%
%
% *Fill in the following comments depending on your focus area(s):
%
% *Area 1: Highlight the artistic and mathematical merit of your video/programming here:
% ( This is our main focus area )
%
% ARTISTIC:
% 
% Our programming focuses on zooming into the "Seahorse Valley" of the
% Mandelbrot Set. At the Seahorse Valley, the main focus of our video is
% panning and zooming in/out of the areas in which (we found) interesting.
% This allowed our video to display a beautiful pattern of the Mandelbrot
% Set, and we were able to display several different fractals that are
% constituents of the Mandelbrot Set. This involved searching for several
% center locations, panning/zooming into a center, then zooming out/panning
% to a different location and zooming in again, and so on.
%
% In order to emphasize the patterns with vibrant colors, 8 sets of the
% cyclic colormap hot(), with every alternating map reversed with the function
% flipud(), were used.
% 
% MATHEMATICAL:
%
% The mathematical merit of our video/programming involves repeated
% iteration for the Mandelbrot Set, of the function z = z.^2 + z0, where
% z0 = 0,1,...
%
% The resolution was increased to 1024 in order to illustrate the detailed
% structure of the boundary of the set, and the depth was increased to 8192
% in order to maximize the level of detail. 
% Since our programming involved standard MATLAB commands running on the
% CPU, this resulted in a significant increase in the execution time.
%
% *Area 2: With the foundational code provided, if you zoom to a certain level of the video, the
% resulting frame image becomes somehow grainy and pixelated. Why does this happen? (Hint: you
% may need to increase the value of depth to notice the pixilation.)
%
% As mentioned above, depth is responsible for determination of detail and
% overal execution time by counting the maximum iteration count. however,
% the iteration counts used as indices into RGB colormap of size..:
%   - The first row of any map specific the color assigned to any points on
%   z0 (initial constant) that lies outside of radius 2 the next few
%   provide shows other colors for the points on the z0 grid that generate
%   trajectories. Lastly, the last row shows the color the points that
%   survive depth iteration.
%   - When the depth is increased this becomes more apparent because there
%   are more details shown and the pixelation becomes more obvious. Having
%   a greater depth creates more detailed images but when we zoom into the
%   image, we need a higher resolution to see them clearly.
%
% *Area 3 (performance improvement): Report before and after each significant change the
% execution times and, if applicable, the memory usage of your primary data structures. Also
% provide a description of the circumstances under which the optimization(s) should be useful.
%
% MAX_FRAMES = 600; RESOLUTION = 1024; MAX_DEPTH = 8192
% Increasing these three values significantly increased the time. Aslo, by
% adding more coordinates and increasing the number of indices, the program
% took longer to execute.
% This code took 4801.370870 seconds to run on my computer, whereas with
% only the path points altered from the given code, the execution time is
% 80.424816 seconds.

