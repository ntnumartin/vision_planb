function [ship_masks,cameraParams,T_ortho,T_align,imageView,panoView,pixel_loc,blending_masks] = initialization()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialization Function
% Outputs:
% - ship_masks:         Binary images | rgb logical
% - cameraParams:       Camera Parameter Object
% - CamOrientation:     Cell Array with 1x3 double vectors
% - CaseOrientation:    Cell Array with 1x3 double vectors
% - T-ortho:            Cell Array with 3x3 projective 2D Objects
% - T-align:            Cell Array with 3x3 affine 2D Objects
% - imageView:          Cell Array of imref2d Objects
% - panoView:           Imref2d Object
% - pixel_loc: 
% - blending_masks:     Binary images | rgb logical
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    h = waitbar(0,'Starting...','Name','Initialization (This can take several minutes!)'); %open waitbar    


    path_calibimages = uigetdir(pwd,'Select the directory of images for initial calibration...'); 
% 
    % Preallocate Variables to improve speed
    I_calib = cell(1,6);
    I_masked = cell(1,6);
    I_lenscorrected = cell(1,6);
    T_ortho = cell(1,6);
    imageView = cell(1,6);
    I_aligned = cell(1,6);
    I_orthorectified = cell(1,6);
    ship_masks = cell(1,6);
    %blending_masks = cell(1,6);

    %% Load calib images
    waitbar(0.05,h,sprintf('Read Calibration Images...'))
    imageScene = imageSet(fullfile(path_calibimages));
    % Read images
    for i=1:6
		k = -1*(-7+i);
        I_calib{i} = read(imageScene, k);
    end

    %% Create Ship Masks 
    waitbar(0.1,h,sprintf('Masking out Ship...'))
%      % Create them once (white should be sea surface)
%      for i=1:6
%      ship_masks{i} = zeros(size(I_calib{i})); % make rgb color mask
%      ship_masks{i}(:,:,1) = double(roipoly(I_calib{i}));
%      for j=1:3
%      ship_masks{i}(:,:,j) = ship_masks{i}(:,:,1); % make rgb color mask
%      end
%      ship_masks{i} = logical(ship_masks{i});
%      end
     
%     load shipmasks
     [path_output,file_output] = uigetfile(pwd,'Select shipmasks...');
     load(fullfile(file_output,path_output));
% 
     clear file_output path_output
    
    % or load existing Masks
    % Set Path for Ship Masks
    % path_shipmasks = uigetdir(pwd,'Select the directory of ship masks...'); 
    % % Load Ship Masks
    % masksScene = imageSet(fullfile(path_shipmasks));
    % % Read Images
    % for i=1:6
        % ship_masks{i} = logical(read(masksScene, i));
    % end

    %% Set Camera Parameters (including lens distortion and intrinsic camera parameters)
    waitbar(0.15,h,sprintf('Setting Camera Parameters...'))
    % % Do Camera Calibration once and find out parameter
    % cameraCalibrator

    %Or set them with known values
    mx = 1/0.0022; % SensorPixelSize in x-Direction is 2.2�m
    my = 1/0.0022; % SensorPixelSize is y-Direction is 2.2�m
    f = 3.5; % Focal Length is 3.5mm
    xc = 1280.5; % Image is 2560px wide %THINK ABOUT WHEN SCALING IMAGES DURING THE WHOLE PROCESS TO ADJUST THIS BEFORE IT IS USED AGAIN
    yc = 960.5; % Image is 1920px high %THINK ABOUT WHEN SCALING IMAGES DURING THE WHOLE PROCESS TO ADJUST THIS BEFORE IT IS USED AGAIN
    s = 0; % No shear in the Sensor
    cameraParams = cameraParameters(...
        'IntrinsicMatrix', [mx*f 0    0;...
                            s    my*f 0;...
                            xc   yc   1],...
        'RadialDistortion',[-0.264910255178320 0.0613496463083729]);
    clear mx my f xc yc s;

    %% Set Camera Orientations
    waitbar(0.2,h,sprintf('Setting Camera Orientations...'))
%     CamOrientation{1} = [+40 0 180];
%     CamOrientation{2} = [+40 0 90];
%     CamOrientation{3} = [+45 0 0];
%     CamOrientation{4} = [+45 0 0];
%     CamOrientation{5} = [+42 0 -90];
%     CamOrientation{6} = [+42 0 -180];
    CamOrientation{1} = [+45 0 180];
    CamOrientation{2} = [+45 0 90];
    CamOrientation{3} = [+45 0 0];
    CamOrientation{4} = [45 0 0];
    CamOrientation{5} = [45 0 -90];
    CamOrientation{6} = [45 0 -180];

    %% Set Case Orientations
    waitbar(0.25,h,sprintf('Setting Case Orientations...'))
%     %CaseOrientation{1} = [-3 -1.8 0.7]; %RIGHT CAMERA MOUNT PARAMETERS
%     %CaseOrientation{2} = [1 1.8 -0.5]; %LEFT CAMERA MOUNT PARAMETERS
% %     CaseOrientation{1} = [1.2 -1.67 1.67]; %RIGHT CAMERA MOUNT PARAMETERS
% %     CaseOrientation{2} = [1.2 1.67 -1.67]; %LEFT CAMERA MOUNT PARAMETERS
%     CaseOrientation{1} = [-2 0 0]; %RIGHT CAMERA MOUNT PARAMETERS
%     CaseOrientation{2} = [1 0 0]; %LEFT CAMERA MOUNT PARAMETERS


    %% Masking out ship
    waitbar(0.3,h,sprintf('Masking out Ship...'))
    for i=1:6
        I_masked{i} = masking_ship(I_calib{i},ship_masks{i},'ShowMessages','on','ShowImages','off');        
    end

    %% Undistort Images
    waitbar(0.35,h,sprintf('Undistort Images...'))
    for i=1:6
        I_lenscorrected{i} = image_undistortion(I_masked{i},cameraParams,'ShowMessages','on','ShowImages','off');
    end
    
    %% Calculate T_ortho (Orthorectification of Images)
%     for m = -2:1:2
%         for n = -2:1:2
%    
     m = 0;
     n = 0;
     %CaseOrientation{1} = [-1.5 -1 1]; %RIGHT CAMERA MOUNT PARAMETERS
%     CaseOrientation{2} = [1.5 1 0]; %LEFT CAMERA MOUNT PARAMETERS
     CaseOrientation{1} = [-1.5 -2 0]; %RIGHT CAMERA MOUNT PARAMETERS
     CaseOrientation{2} = [0 0 0]; %LEFT CAMERA MOUNT PARAMETERS


    
    waitbar(0.4,h,sprintf('Calculate T-ortho and imageView...'))
    for i=1:3
    [T_ortho{i},imageView{i}] = T_ortho_calc(I_lenscorrected{i},CamOrientation{i},CaseOrientation{1},cameraParams,'ScaleFactor',1,'ShowMessages','on','ShowImages','off');
    end
    for i=4:6
    [T_ortho{i},imageView{i}] = T_ortho_calc(I_lenscorrected{i},CamOrientation{i},CaseOrientation{2},cameraParams,'ScaleFactor',1,'ShowMessages','on','ShowImages','off'); 
    end

    %% Project Images to calculate later T_align
    waitbar(0.5,h,sprintf('Rectify images...'))
    for i=1:6
    I_orthorectified{i} = imwarp(I_lenscorrected{i},T_ortho{i},'linear','OutputView',imageView{i},'Fill',0,'SmoothEdges',true);
    end
    
    %% Find features in images
%     [Feature{1},Points{1}] = detectfeatures(I_orthorectified{1},'ShowMessages','on','ShowImages','on');
%     [Feature{2},Points{2}] = detectfeatures(I_orthorectified{2},'ShowMessages','on','ShowImages','on');
%     [Feature{3},Points{3}] = detectfeatures(I_orthorectified{3},'ShowMessages','on','ShowImages','on');
%     [Feature{4},Points{4}] = detectfeatures(I_orthorectified{4},'ShowMessages','on','ShowImages','on');
%     [Feature{5},Points{5}] = detectfeatures(I_orthorectified{5},'ShowMessages','on','ShowImages','on');
%     [Feature{6},Points{6}] = detectfeatures(I_orthorectified{6},'ShowMessages','on','ShowImages','on');
%  
    %% Estimate T_align with feature detection and matching
    waitbar(0.55,h,sprintf('Estimate T-align and pixel_loc...'))
    T_align{1} = affine2d(eye(3,3));
    [T_align{2},pixel_loc{1}{1},pixel_loc{1}{2}] = estimate_translation(I_orthorectified{1},I_orthorectified{2},Feature{1},Feature{2},Points{1},Points{2},'ShowMessages','on','ShowImages','off');
    [T_align{3},pixel_loc{2}{2},pixel_loc{2}{3}] = estimate_translation(I_orthorectified{2},I_orthorectified{3},Feature{2},Feature{3},Points{2},Points{3},'ShowMessages','on','ShowImages','off');
    [T_align{4},pixel_loc{3}{3},pixel_loc{3}{4}] = estimate_translation(I_orthorectified{3},I_orthorectified{4},Feature{3},Feature{4},Points{3},Points{4},'ShowMessages','on','ShowImages','off');
    [T_align{5},pixel_loc{4}{4},pixel_loc{4}{5}] = estimate_translation(I_orthorectified{4},I_orthorectified{5},Feature{4},Feature{5},Points{4},Points{5},'ShowMessages','on','ShowImages','off');
    [T_align{6},pixel_loc{5}{5},pixel_loc{5}{6}] = estimate_translation(I_orthorectified{5},I_orthorectified{6},Feature{5},Feature{6},Points{5},Points{6},'ShowMessages','on','ShowImages','off');

% matchedPoints1=[6268,549;6515,783;6381,833;6154,994;6772,1152;6606,1251;6255,1326;7123,1462;7586,2027;7835,2568];
% matchedPoints2a=[426,4237;698,4410;461,4584;339,4671;1014,4714;896,4821;505,5014;1381,4908;1902,5342;2222,5737];
% matchedPoints2b=[362,3008;549,3286;788,3438;879,2407;1054,2510;1094,2765;1305,2868;1218,3047;1003,3282;1699,2753;2101,2259;1898,2152;1986,1849;2551,1622];
% matchedPoints3a=[4843,5439;5011,5682;5263,5870;5169,4864;5337,4928;5401,5103;5620,5207;5609,5386;5445,5671;5963,5009;6205,4501;5946,4501;5922,4276;6356,4010];
% matchedPoints3b=[3797,2262;4246,2372;3839,2815;4033,2730;4240,2669;3979,3209;4319,2948;4562,2724;4143,3300;4604,3064;4009,3622;4179,3562;4361,3489];
% matchedPoints4a=[3870,2467;4318,2551;4073,2991;4276,2898;4420,2847;4344,3355;4555,3093;4741,2847;4547,3456;4877,3169;4538,3769;4648,3668;4792,3592];
% matchedPoints4b=[2390,3681;2647,4161;2743,3941;2861,4474;3170,4356;3022,4945;3418,4762;3771,4876;3830,5019;3963,5183;3876,5372;3495,5604;3403,5462];
% matchedPoints5a=[3952,2620;4290,3025;4257,2753;4517,3277;4681,3030;4745,3629;5014,3382;5380,3399;5455,3538;5615,3676;5560,3887;5233,4112;5147,4009];
% matchedPoints5b=[3712,6664;4110,6313;4475,5860;4641,5543;5135,5561;5382,5646;5393,5893;5492,5495;5739,5263;5621,5108;5533,5001;5382,5008;5227,4879;5059,4996];
% matchedPoints6=[2578,2002;2869,1641;3103,1204;3176,886;3692,815;3923,827;3960,985;4008,681;4187,438;4075,289;3990,195;3832,198;3659,56;3501,220];
% 
%     T_align{1} = affine2d(eye(3,3));
%     [T_align{2},pixel_loc{1}{1},pixel_loc{1}{2}] = estimate_translation_inject(I_orthorectified{1},I_orthorectified{2},matchedPoints1,matchedPoints2a,'ShowMessages','on','ShowImages','on');
%     [T_align{3},pixel_loc{2}{2},pixel_loc{2}{3}] = estimate_translation_inject(I_orthorectified{2},I_orthorectified{3},matchedPoints2b,matchedPoints3a,'ShowMessages','on','ShowImages','on');
%     [T_align{4},pixel_loc{3}{3},pixel_loc{3}{4}] = estimate_translation_inject(I_orthorectified{3},I_orthorectified{4},matchedPoints3b,matchedPoints4a,'ShowMessages','on','ShowImages','on');
%     [T_align{5},pixel_loc{4}{4},pixel_loc{4}{5}] = estimate_translation_inject(I_orthorectified{4},I_orthorectified{5},matchedPoints4b,matchedPoints5a,'ShowMessages','on','ShowImages','on');
%     [T_align{6},pixel_loc{5}{5},pixel_loc{5}{6}] = estimate_translation_inject(I_orthorectified{5},I_orthorectified{6},matchedPoints5b,matchedPoints6,'ShowMessages','on','ShowImages','on');


%     
%     %% Estimate T_align with feature detection and matching
%     waitbar(0.55,h,sprintf('Estimate T-align and pixel_loc...'))
%     T_align{1} = affine2d(eye(3,3));
%     [T_align{2},pixel_loc{1}{1},pixel_loc{1}{2}] = estimate_translation(I_orthorectified{1},I_orthorectified{2},'ShowMessages','on','ShowImages','off');
%     [T_align{3},pixel_loc{2}{2},pixel_loc{2}{3}] = estimate_translation(I_orthorectified{2},I_orthorectified{3},'ShowMessages','on','ShowImages','off');
%     [T_align{4},pixel_loc{3}{3},pixel_loc{3}{4}] = estimate_translation(I_orthorectified{3},I_orthorectified{4},'ShowMessages','on','ShowImages','off');
%     [T_align{5},pixel_loc{4}{4},pixel_loc{4}{5}] = estimate_translation(I_orthorectified{4},I_orthorectified{5},'ShowMessages','on','ShowImages','off');
%     [T_align{6},pixel_loc{5}{5},pixel_loc{5}{6}] = estimate_translation(I_orthorectified{5},I_orthorectified{6},'ShowMessages','on','ShowImages','off');

    %% Invert T_align matrizes to have image 1 as reference image
    waitbar(0.8,h,sprintf('Invert T-align Matrices...'))
    for i=2:6
        T_align{i}.T = T_align{i-1}.T*T_align{i}.T;
    end

    for i=1:6
        T_align{i}=invert(T_align{i});
    end

    %% Calculate panoView
    waitbar(0.85,h,sprintf('Calculate panoView...'))
    panoView = calculate_panosize(T_align,I_orthorectified,'ScaleFactor',3,'ShowMessages','on');

    %% Place Images on Panorama to create blending masks easier
    waitbar(0.9,h,sprintf('Place Images on panorama...'))
    for i=1:6
        I_aligned{i} = place_on_pano(I_orthorectified{i},T_align{i},panoView,'ShowMessages','on','ShowImages','on');
    end

    %% Set blending masks
    waitbar(0.95,h,sprintf('Make Blending masks...'))
   
    %% Set blending masks
    waitbar(0.95,h,sprintf('Make Blending masks...'))
    % Create blending masks by hand with roipoly (white area should be at the next image)
    for j=1:5
        blending_masks{j} = zeros(size(I_aligned{j}));
    end
    blending_masks{1}(:,:,1) = double(roipoly(I_aligned{1}+I_aligned{2}));
    panorama = image_stitching(I_aligned{1},I_aligned{2},'ShowMessages','on');
    blending_masks{2}(:,:,1) = double(roipoly(panorama+I_aligned{3}));
    panorama = image_stitching(panorama,I_aligned{3},'ShowMessages','on');
    blending_masks{3}(:,:,1) = double(roipoly(panorama+I_aligned{4}));
    panorama = image_stitching(panorama,I_aligned{4},'ShowMessages','on');
    blending_masks{4}(:,:,1) = double(roipoly(panorama+I_aligned{5}));
    panorama = image_stitching(panorama,I_aligned{5},'ShowMessages','on');
    blending_masks{5}(:,:,1) = double(roipoly(panorama+I_aligned{6}));
    
    for j=1:5
        for k=1:3
            blending_masks{j}(:,:,k) = blending_masks{j}(:,:,1);
        end
        blending_masks{j} = logical(blending_masks{j});
    end
    
    panorama = image_stitching(panorama,I_aligned{6},'ShowMessages','on');
    imshow(panorama)
     %save(strcat('Init_C1-',num2str(m),'-0-0_C2-',num2str(n),'-0-0.mat'),'panorama')
%         end
%     end
%       figure
%       imshow(panorama)
%      title(strcat('Cam1:',num2str(m),'Cam2:0'))
     %     blending_masks{5}(:,:,1) = double(roipoly(panorama+I_aligned{6}));
%     for j=1:5
%         for k=1:3
%             blending_masks{j}(:,:,k) = blending_masks{j}(:,:,1);
%         end
%         blending_masks{j} = logical(blending_masks{j});
%     end

    % or load blending masks; 
%     path_blendingmasks = uigetdir(pwd,'Select the directory of blending masks...');
%     blendingScene = imageSet(fullfile(path_blendingmasks));
%     % Read images
%     for i=1:5
%         blending_masks{i} = logical(read(blendingScene, i));
%     end
    %end

waitbar(1,h,sprintf('Processing succeded!'))
end

%% SUBFUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Ims = masking_ship(I,Im,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inputs
% I: Image to be masked | Format uint8 and rgb | 0..255 Pixel Values
% Im: Mask | Format logical and rgb
%
% Optional Input Arguments
% 'ShowMessages' | 'on' or 'off' | default is 'off' | Displays Messages
% 'ShowImages' | 'on' or 'off' | default is 'off' | Displays Images
% 
% Outputs
% Ims: masked Image | Format uint8 and rgb | 0..255 Pixel Values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;
defaultShowImages = 'off';
expectedShowImages = {'on','off'};
defaultShowMessages = 'off';
expectedShowMessages = {'on','off'};
classes = {'uint8'};
classes2 = {'logical'};
attributes = {'size',[NaN,NaN,3]};
addRequired(p,'I',@(x)validateattributes(x,classes,attributes));
addRequired(p,'Im',@(x)validateattributes(x,classes2,attributes));
addParameter(p,'ShowImages',defaultShowImages,...
                 @(x) any(validatestring(x,expectedShowImages)));
addParameter(p,'ShowMessages',defaultShowMessages,...
                 @(x) any(validatestring(x,expectedShowMessages)));
parse(p,I,Im,varargin{:})


Ims = uint8(double(I).*Im); % Apply Masking

if strcmp(p.Results.ShowImages,'on')
    f=figure; imshowpair(I,Im);
    title('Green: Mask Image | Violett: Remaining Image');
    pause();
    close(f);
end

if strcmp(p.Results.ShowMessages,'on')
    fprintf('Image masked!\n');
end

end

%%
function Iud = image_undistortion(I,cameraParams,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inputs
% I: Image to be undistorted | Format uint8 and rgb | 0..255 Pixel Values
% cameraParams: Camera Parameters | cameraParameters Object
% 
% Optional Input Arguments
% 'ShowMessages' | 'on' or 'off' | default is 'off' | Displays Messages
% 'ShowImages' | 'on' or 'off' | default is 'off' | Displays Images
% 
% Outputs
% Iud: undistorted Image | Format uint8 and rgb | 0..255 Pixel Values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;
defaultShowImages = 'off';
expectedShowImages = {'on','off'};
defaultShowMessages = 'off';
expectedShowMessages = {'on','off'};
ClassName = 'cameraParameters';
classes = {'uint8'};
attributes = {'size',[NaN,NaN,3]};
addRequired(p,'I',@(x)validateattributes(x,classes,attributes));
addRequired(p,'cameraParams',@(x)isa(x,ClassName));
addParameter(p,'ShowImages',defaultShowImages,...
                 @(x) any(validatestring(x,expectedShowImages)));
addParameter(p,'ShowMessages',defaultShowMessages,...
                 @(x) any(validatestring(x,expectedShowMessages)));
parse(p,I,cameraParams,varargin{:})

% Calculate Image Size
width = size(I,1);
heigth = size(I,2);

% Correct for Radial and Tangential Distortion
Iud = undistortImage(I, cameraParams,'OutputView','Full');

% Resize Image like DistortImage
Iud = imresize(Iud,[width heigth]);

if strcmp(p.Results.ShowImages,'on')
    f=figure; imshowpair(I,Iud,'montage');
    title('Left side: Original Image | Right side: undistorted Image');
    pause();
    close(f);
end

if strcmp(p.Results.ShowMessages,'on')
    fprintf('Image undistorted!\n');
end

end

%%
function [T_ortho,imageView] = T_ortho_calc(I,camOrientation,caseOrientation,cameraParams,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inputs
% I: Image to be projected | Format uint8 and rgb | 0..255 Pixel Values
% camOrientation: 3x1 Matrix containing X,Y,Z Angle for 
%                    CamOrientation | double
% caseOrientation: 3x1 Matrix containing X,Y,Z Angle for Case | double
% K: 3x3 Camera Matrix | double 
% 
% Optional Input Arguments
% 'ScaleFactor' | double | Image Size will be scaled down >1 for small
% 'ShowMessages' | 'on' or 'off' | default is 'off' | Displays Messages
% 'ShowImages' | 'on' or 'off' | default is 'off' | Displays Images
% 
% Outputs
% Ip: projected Image | Format uint8 and rgb | 0..255 Pixel Values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;
defaultShowImages = 'off';
expectedShowImages = {'on','off'};
defaultShowMessages = 'off';
expectedShowMessages = {'on','off'};
defaultScaleFactor = 1;
classes = {'uint8'};
classes2 = {'double'};
attributes = {'size',[NaN,NaN,3]};
attributes2 = {'size',[1,3]};
addRequired(p,'I',@(x)validateattributes(x,classes,attributes));
addRequired(p,'cameraOrientation',@(x)validateattributes(x,classes2,attributes2));
addRequired(p,'caseOrientation',@(x)validateattributes(x,classes2,attributes2));
addRequired(p,'cameraParams');
addParameter(p,'ScaleFactor',defaultScaleFactor,@isnumeric);
addParameter(p,'ShowImages',defaultShowImages,...
                 @(x) any(validatestring(x,expectedShowImages)));
addParameter(p,'ShowMessages',defaultShowMessages,...
                 @(x) any(validatestring(x,expectedShowMessages)));
parse(p,I,camOrientation,caseOrientation,cameraParams,varargin{:})
   
    rotx = caseOrientation(1);
    roty = caseOrientation(2);
    rotz = caseOrientation(3);

    Rx = [1 0           0           ;...
          0 cosd(rotx)  -sind(rotx) ;...
          0 sind(rotx)  cosd(rotx)] ;

    Ry = [cosd(roty)    0   sind(roty)  ;...
          0             1   0           ;...
          -sind(roty)   0   cosd(roty)] ;

    Rz = [cosd(rotz)    -sind(rotz)     0   ;...
          sind(rotz)    cosd(rotz)      0   ;...
          0             0              1]   ;

    % Set up Final Rotation Matrix
    Rc = Rz * Ry * Rx;

    % Read Camera Orientation Angles
    rotx = camOrientation(1);
    roty = camOrientation(2);
    rotz = camOrientation(3);

    % Construct Rotation Matrices
    Rx = [1 0           0           ;...
          0 cosd(rotx)  -sind(rotx) ;...
          0 sind(rotx)  cosd(rotx)] ;

    Ry = [cosd(roty)    0   sind(roty)  ;...
          0             1   0           ;...
          -sind(roty)   0   cosd(roty)] ;

    Rz = [cosd(rotz)    -sind(rotz)     0   ;...
          sind(rotz)    cosd(rotz)      0   ;...
          0             0              1]   ;

    % Set up Final Rotation Matrix
    R = Rz * Ry * Rx;

    R = Rc*R;

    % Build Homography
    H = cameraParams.IntrinsicMatrix' * R / cameraParams.IntrinsicMatrix';

    % Make Projective2d
    T_ortho = projective2d(H');

    % Calculate limits for projected Images
    [xlim,ylim] = outputLimits(T_ortho, [1 size(I,2)], [1 size(I,1)]);

    % Width and height of projected Images
    width  = round((max(xlim) - min(xlim))/p.Results.ScaleFactor);
    height = round((max(ylim) - min(ylim))/p.Results.ScaleFactor);

    % Calculate imref2d object
    imageView = imref2d([height width], xlim, ylim);

    if strcmp(p.Results.ShowMessages,'on')
        fprintf('Calculation of T_ortho complete!\n');
    end
end

%%

function [Features,ValidPoints]= detectfeatures(I1,varargin)
p = inputParser;
defaultShowImages = 'off';
expectedShowImages = {'on','off'};
defaultShowMessages = 'off';
expectedShowMessages = {'on','off'};
classes = {'uint8'};
attributes = {'size',[NaN,NaN,3]};
addRequired(p,'I1',@(x)validateattributes(x,classes,attributes));
addParameter(p,'ShowImages',defaultShowImages,...
                 @(x) any(validatestring(x,expectedShowImages)));
addParameter(p,'ShowMessages',defaultShowMessages,...
                 @(x) any(validatestring(x,expectedShowMessages)));
parse(p,I1,varargin{:})

% Grayscale Images
I1 = rgb2gray(I1);
%% Detect Features off Image 1
points1 = detectSURFFeatures(I1,'NumOctaves',1,'NumScaleLevels',16,'MetricThreshold',100);
[features1, points1] = extractFeatures(I1, points1);

% Erase Outlier Features
mask1 = I1;
mask1(mask1>0) = 1;
maskidx1=find(mask1>0);
pointsidx1 = sub2ind(size(I1),round(points1.Location(:,2)),round(points1.Location(:,1)));
validPoints1=ismember(pointsidx1,maskidx1);
notValidPointsidx1 = find(validPoints1==0);
validpoints1 = points1.Location;
validpoints1(notValidPointsidx1,:)=[];
features1(notValidPointsidx1,:) = [];

Features = features1;
ValidPoints = validpoints1;

if strcmp(p.Results.ShowImages,'on')
    f1=figure; imshow(I1);
    title('Detected Features on Image1');
    hold on;
    points1.plot
    hold off;
    pause(0.5)
    close(f1);
end

if strcmp(p.Results.ShowMessages,'on')
    fprintf('Detection of features complete\n');
end

end

function [T_align,PixelLoc1,PixelLoc2] = estimate_translation(I1,I2,Features1,Features2,ValidPoints1,ValidPoints2,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Inputs
% I1: Image 1 | rgb uint8 0..255
% I2: Image 2 | rgb uint8 0..255
%
% Optional Input Arguments (Name value pairs)
% 'ShowMessages' | 'on' or 'off' | default is 'off' | Displays Messages
% 'ShowImages' | 'on' or 'off' | default is 'off' | Displays Images
% 
% Outputs
% T: 1x1 affine 2d Object
% PixelLoc1: Locations [xi yi] of Feature Points 1 | numeric Nx2 Array
% PixelLoc2: Locations [xi yi] of Feature Points 2 | numeric Nx2 Array
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;
defaultShowImages = 'off';
expectedShowImages = {'on','off'};
defaultShowMessages = 'off';
expectedShowMessages = {'on','off'};
classes = {'uint8'};
classes2 = {'single'};
attributes = {'size',[NaN,NaN,3]};
attributes2 = {'size',[NaN,NaN]};
addRequired(p,'I1',@(x)validateattributes(x,classes,attributes));
addRequired(p,'I2',@(x)validateattributes(x,classes,attributes));
addRequired(p,'Features1',@(x)validateattributes(x,classes2,attributes2));
addRequired(p,'Features2',@(x)validateattributes(x,classes2,attributes2));
addRequired(p,'ValidPoints1',@(x)validateattributes(x,classes2,attributes2));
addRequired(p,'ValidPoints2',@(x)validateattributes(x,classes2,attributes2));
addParameter(p,'ShowImages',defaultShowImages,...
                 @(x) any(validatestring(x,expectedShowImages)));
addParameter(p,'ShowMessages',defaultShowMessages,...
                 @(x) any(validatestring(x,expectedShowMessages)));
parse(p,I1,I2,Features1,Features2,ValidPoints1,ValidPoints2,varargin{:})

% Grayscale Images
I1 = rgb2gray(I1);
I2 = rgb2gray(I2);

%% Detect Features off Image 1
validpoints1 = ValidPoints1;
features1 = Features1;


%% Detect Features off Image 2
validpoints2 = ValidPoints2;
features2 = Features2;

%% Find corresponding Points between two Images
indexPairs = matchFeatures(features1, features2,'Method','Approximate','MatchThreshold',0.1,'MaxRatio',0.4,'Unique',true,'Metric','SSD');
matchedPoints1 = validpoints1(indexPairs(:,1), :);
matchedPoints2 = validpoints2(indexPairs(:,2), :);

if strcmp(p.Results.ShowImages,'on')
    f3 = figure; showMatchedFeatures(I1,I2,matchedPoints1,matchedPoints2);
    title('Matching Features');
    legend('matchedPts1','matchedPts2');
    pause(0.5)
    close(f3);
end

%% Estimate geometric Transform for I2
%[T_align, matchedPoints1, matchedPoints2,status] = estimateGeometricTransform(matchedPoints1, matchedPoints2,...
%    'affine', 'Confidence', 99, 'MaxNumTrials', 5000, 'MaxDistance',1.5); %1.5 for right side

[T_align, matchedPoints1, matchedPoints2,status] = estimateGeometricTransform(matchedPoints1, matchedPoints2,...
    'affine', 'Confidence', 60, 'MaxNumTrials', 50000, 'MaxDistance',50); %1.5 for right side

if status == 1
    fprintf('WARNING: No Matches found!\n');
    return;
end

%% Alternative Estimate Translation
% x = mean(matchedPoints2(:,1)-matchedPoints1(:,1));
% y = mean(matchedPoints2(:,2)-matchedPoints1(:,2));
% 
% Tl = [ 1 0 x; 0 1 y; 0 0 1];
% T = projective2d(Tl');

%% Extract Locations of Features
PixelLoc1 = round(matchedPoints1);
PixelLoc2 = round(matchedPoints2);

% %% Calculate Average Pixel Intensity
% linidx1=sub2ind(size(I1),round(matchedPoints1(:,2)),round(matchedPoints1(:,1)));
% linidx2=sub2ind(size(I2),round(matchedPoints2(:,2)),round(matchedPoints2(:,1)));
% PixelIntense1 = double(I1(linidx1));
% PixelIntense2 = double(I2(linidx2));

%% Show Images and Messages
if strcmp(p.Results.ShowImages,'on')
    f4 = figure; showMatchedFeatures(I1,I2,matchedPoints1,matchedPoints2,'montage');
    title('Matching Features after Geometric Transform Estimation');
    legend('matchedPts1','matchedPts2');
end
if strcmp(p.Results.ShowMessages,'on')
    fprintf('Feature Matching of Images complete!\n');
end

%%%TRY
% sf=sign(T.T(1,1))*sqrt(T.T(1,1)^2+T.T(2,1)^2);
% T.T(3,1) = T.T(3,1) * sf;
% T.T(3,2) = T.T(3,2) * sf;
% T.T(1:2,1:2) = eye(2,2);

% T.T(1,2) = 0;
% T.T(2,1) = 0;

end

function [T_align,PixelLoc1,PixelLoc2] = estimate_translation_inject(I1,I2,matchedFeatures1,matchedFeatures2,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Inputs
% I1: Image 1 | rgb uint8 0..255
% I2: Image 2 | rgb uint8 0..255
%
% Optional Input Arguments (Name value pairs)
% 'ShowMessages' | 'on' or 'off' | default is 'off' | Displays Messages
% 'ShowImages' | 'on' or 'off' | default is 'off' | Displays Images
% 
% Outputs
% T: 1x1 affine 2d Object
% PixelLoc1: Locations [xi yi] of Feature Points 1 | numeric Nx2 Array
% PixelLoc2: Locations [xi yi] of Feature Points 2 | numeric Nx2 Array
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;
defaultShowImages = 'off';
expectedShowImages = {'on','off'};
defaultShowMessages = 'off';
expectedShowMessages = {'on','off'};
classes = {'uint8'};
classes2 = {'double'};
attributes = {'size',[NaN,NaN,3]};
attributes2 = {'size',[NaN,2]};
addRequired(p,'I1',@(x)validateattributes(x,classes,attributes));
addRequired(p,'I2',@(x)validateattributes(x,classes,attributes));
addRequired(p,'matchedFeatures1',@(x)validateattributes(x,classes2,attributes2));
addRequired(p,'matchedFeatures2',@(x)validateattributes(x,classes2,attributes2));
addParameter(p,'ShowImages',defaultShowImages,...
                 @(x) any(validatestring(x,expectedShowImages)));
addParameter(p,'ShowMessages',defaultShowMessages,...
                 @(x) any(validatestring(x,expectedShowMessages)));
parse(p,I1,I2,matchedFeatures1,matchedFeatures2,varargin{:})

% Grayscale Images
I1 = rgb2gray(I1);
I2 = rgb2gray(I2);



%% Find corresponding Points between two Images
matchedPoints1 = matchedFeatures1;
matchedPoints2 = matchedFeatures2;

if strcmp(p.Results.ShowImages,'on')
    f3 = figure; showMatchedFeatures(I1,I2,matchedPoints1,matchedPoints2);
    title('Matching Features');
    legend('matchedPts1','matchedPts2');
    pause(0.5)
    close(f3);
end

%% Estimate geometric Transform for I2
%[T_align, matchedPoints1, matchedPoints2,status] = estimateGeometricTransform(matchedPoints1, matchedPoints2,...
%    'affine', 'Confidence', 99, 'MaxNumTrials', 5000, 'MaxDistance',1.5); %1.5 for right side

[T_align, matchedPoints1, matchedPoints2,status] = estimateGeometricTransform(matchedPoints1, matchedPoints2,...
    'affine', 'Confidence', 1, 'MaxNumTrials', 50000, 'MaxDistance',200); %1.5 for right side

if status == 1
    fprintf('WARNING: No Matches found!\n');
    return;
end

%% Alternative Estimate Translation
% x = mean(matchedPoints2(:,1)-matchedPoints1(:,1));
% y = mean(matchedPoints2(:,2)-matchedPoints1(:,2));
% 
% Tl = [ 1 0 x; 0 1 y; 0 0 1];
% T = projective2d(Tl');

%% Extract Locations of Features
PixelLoc1 = round(matchedPoints1);
PixelLoc2 = round(matchedPoints2);

% %% Calculate Average Pixel Intensity
% linidx1=sub2ind(size(I1),round(matchedPoints1(:,2)),round(matchedPoints1(:,1)));
% linidx2=sub2ind(size(I2),round(matchedPoints2(:,2)),round(matchedPoints2(:,1)));
% PixelIntense1 = double(I1(linidx1));
% PixelIntense2 = double(I2(linidx2));

%% Show Images and Messages
if strcmp(p.Results.ShowImages,'on')
    f4 = figure; showMatchedFeatures(I1,I2,matchedPoints1,matchedPoints2,'montage');
    title('Matching Features after Geometric Transform Estimation');
    legend('matchedPts1','matchedPts2');
end
if strcmp(p.Results.ShowMessages,'on')
    fprintf('Feature Matching of Images complete!\n');
end

%%%TRY
% sf=sign(T.T(1,1))*sqrt(T.T(1,1)^2+T.T(2,1)^2);
% T.T(3,1) = T.T(3,1) * sf;
% T.T(3,2) = T.T(3,2) * sf;
% T.T(1:2,1:2) = eye(2,2);

% T.T(1,2) = 0;
% T.T(2,1) = 0;

end
% function [T_align,PixelLoc1,PixelLoc2] = estimate_translation(I1,I2,varargin)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% % Inputs
% % I1: Image 1 | rgb uint8 0..255
% % I2: Image 2 | rgb uint8 0..255
% %
% % Optional Input Arguments (Name value pairs)
% % 'ShowMessages' | 'on' or 'off' | default is 'off' | Displays Messages
% % 'ShowImages' | 'on' or 'off' | default is 'off' | Displays Images
% % 
% % Outputs
% % T: 1x1 affine 2d Object
% % PixelLoc1: Locations [xi yi] of Feature Points 1 | numeric Nx2 Array
% % PixelLoc2: Locations [xi yi] of Feature Points 2 | numeric Nx2 Array
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% p = inputParser;
% defaultShowImages = 'off';
% expectedShowImages = {'on','off'};
% defaultShowMessages = 'off';
% expectedShowMessages = {'on','off'};
% classes = {'uint8'};
% attributes = {'size',[NaN,NaN,3]};
% addRequired(p,'I1',@(x)validateattributes(x,classes,attributes));
% addRequired(p,'I2',@(x)validateattributes(x,classes,attributes));
% addParameter(p,'ShowImages',defaultShowImages,...
%                  @(x) any(validatestring(x,expectedShowImages)));
% addParameter(p,'ShowMessages',defaultShowMessages,...
%                  @(x) any(validatestring(x,expectedShowMessages)));
% parse(p,I1,I2,varargin{:})
% 
% % Grayscale Images
% I1 = rgb2gray(I1);
% I2 = rgb2gray(I2);
% 
% %% Detect Features off Image 1
% points1 = detectSURFFeatures(I1,'NumOctaves',1,'NumScaleLevels',16,'MetricThreshold',100);
% [features1, points1] = extractFeatures(I1, points1);
% 
% % Erase Outlier Features
% mask1 = I1;
% mask1(mask1>0) = 1;
% maskidx1=find(mask1>0);
% pointsidx1 = sub2ind(size(I1),round(points1.Location(:,2)),round(points1.Location(:,1)));
% validPoints1=ismember(pointsidx1,maskidx1);
% notValidPointsidx1 = find(validPoints1==0);
% validpoints1 = points1.Location;
% validpoints1(notValidPointsidx1,:)=[];
% features1(notValidPointsidx1,:) = [];
% 
% 
% if strcmp(p.Results.ShowImages,'on')
%     f1=figure; imshow(I1);
%     title('Detected Features on Image1');
%     hold on;
%     points1.plot
%     hold off;
%     pause(0.5)
%     close(f1);
% end
% 
% 
% %% Detect Features off Image 2
% points2 = detectSURFFeatures(I2,'NumOctaves',1,'NumScaleLevels',16,'MetricThreshold',100);
% [features2, points2] = extractFeatures(I2, points2);
% 
% % Erase Outlier Features
% mask2 = I2;
% mask2(mask2>0) = 1;
% maskidx2=find(mask2>0);
% pointsidx2 = sub2ind(size(I2),round(points2.Location(:,2)),round(points2.Location(:,1)));
% validPoints2=ismember(pointsidx2,maskidx2);
% notValidPointsidx2 = find(validPoints2==0);
% validpoints2 = points2.Location;
% validpoints2(notValidPointsidx2,:)=[];
% features2(notValidPointsidx2,:) = [];
% 
% 
% if strcmp(p.Results.ShowImages,'on')
%     f2 = figure; imshow(I2);
%     title('Detected Features on Image2');
%     hold on;
%     points2.plot
%     hold off;
%     pause(0.5)
%     close(f2);
% end
% 
% %% Find corresponding Points between two Images
% indexPairs = matchFeatures(features1, features2,'Method','Approximate','MatchThreshold',50,'MaxRatio',0.5,'Unique',true,'Metric','SSD');
% matchedPoints1 = validpoints1(indexPairs(:,1), :);
% matchedPoints2 = validpoints2(indexPairs(:,2), :);
% 
% if strcmp(p.Results.ShowImages,'on')
%     f3 = figure; showMatchedFeatures(I1,I2,matchedPoints1,matchedPoints2);
%     title('Matching Features');
%     legend('matchedPts1','matchedPts2');
%     pause(0.5)
%     close(f3);
% end
% 
% %% Estimate geometric Transform for I2
% [T_align, matchedPoints1, matchedPoints2,status] = estimateGeometricTransform(matchedPoints1, matchedPoints2,...
%     'similarity', 'Confidence', 75, 'MaxNumTrials', 1000, 'MaxDistance',25); %1.5 for right side
% 
% if status == 1
%     fprintf('WARNING: No Matches found!\n');
%     return;
% end
% 
% %% Alternative Estimate Translation
% % x = mean(matchedPoints2(:,1)-matchedPoints1(:,1));
% % y = mean(matchedPoints2(:,2)-matchedPoints1(:,2));
% % 
% % Tl = [ 1 0 x; 0 1 y; 0 0 1];
% % T = projective2d(Tl');
% 
% %% Extract Locations of Features
% PixelLoc1 = round(matchedPoints1);
% PixelLoc2 = round(matchedPoints2);
% 
% % %% Calculate Average Pixel Intensity
% % linidx1=sub2ind(size(I1),round(matchedPoints1(:,2)),round(matchedPoints1(:,1)));
% % linidx2=sub2ind(size(I2),round(matchedPoints2(:,2)),round(matchedPoints2(:,1)));
% % PixelIntense1 = double(I1(linidx1));
% % PixelIntense2 = double(I2(linidx2));
% 
% %% Show Images and Messages
% if strcmp(p.Results.ShowImages,'on')
%     f4 = figure; showMatchedFeatures(I1,I2,matchedPoints1,matchedPoints2,'montage');
%     title('Matching Features after Geometric Transform Estimation');
%     legend('matchedPts1','matchedPts2');
% end
% if strcmp(p.Results.ShowMessages,'on')
%     fprintf('Feature Matching of Images complete!\n');
% end
% 
% %%%TRY
% % sf=sign(T.T(1,1))*sqrt(T.T(1,1)^2+T.T(2,1)^2);
% % T.T(3,1) = T.T(3,1) * sf;
% % T.T(3,2) = T.T(3,2) * sf;
% % T.T(1:2,1:2) = eye(2,2);
% 
% % T.T(1,2) = 0;
% % T.T(2,1) = 0;
% 
% end

%%
function panoView = calculate_panosize(T,I,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Inputs
% T: 1xN Cell which contains 1x1 affine 2d Objects | N = Number of Tforms
% I: 1xN cell containing Images | rgb uint8 0..255
%
% Optional Input Arguments (Name value pairs)
% 'ShowMessages' | 'on' or 'off' | default is 'off' | Displays Messages
% 
% Outputs
% panoramaView: Imref2d Object 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


p = inputParser;
defaultShowMessages = 'off';
expectedShowMessages = {'on','off'};
defaultScaleFactor = 1;
%classes = {'uint8'};
%attributes = {'size',[NaN,NaN,3]};
addRequired(p,'T');
addRequired(p,'I');
addParameter(p,'ShowMessages',defaultShowMessages,...
                 @(x) any(validatestring(x,expectedShowMessages)));
addParameter(p,'ScaleFactor',defaultScaleFactor,@isnumeric);
parse(p,T,I,varargin{:})

% Define Number of Transformations
counter = [1 2 3 4 5 6].*~cellfun('isempty',T);
counter(counter==0)=[];

% Pre Allocate Variables
xlim = zeros(length(counter),2);
ylim = zeros(length(counter),2);

% Find output limits for projected Images
for i=counter
	[xlim(i,:),ylim(i,:)] = outputLimits(T{i}, [1 size(I{i},2)], [1 size(I{i},1)]);
end

% Find the minimum and maximum of output limits
xMin = min(xlim(:));
xMax = max(xlim(:));

yMin = min(ylim(:));
yMax = max(ylim(:));

% Width and height of preprocessed Images
width  = round((xMax - xMin)/p.Results.ScaleFactor);
height = round((yMax - yMin)/p.Results.ScaleFactor);

% Create a 2-D spatial reference object defining the size of the preprocessed Images
xLimits = [xMin xMax];
yLimits = [yMin yMax];
panoView = imref2d([height width], xLimits, yLimits);

if strcmp(p.Results.ShowMessages,'on')
    fprintf('Panorama Size Calculation complete!\n');
end

if height > 12000 || width > 12000
    fprintf('WARNING: Panorama Size %i x %i too big!\n',height,width);
    pause();
    return;
end

end

%%
function Ipano = place_on_pano(I,T,panoramaView,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Inputs
% I: Image | grayscale or rgb uint8 0..255
% T: 1x1 affine 2d Objects
% panoramaView: Imref2d Object 
%
% Optional Input Arguments (Name value pairs)
% 'ShowMessages' | 'on' or 'off' | default is 'off' | Displays Messages
% 'ShowImages' | 'on' or 'off' | default is 'off' | Displays Images
% 
% Outputs
% Ipano: Projected Image onto Panorama |rgb uint8 0..255
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;
defaultShowImages = 'off';
expectedShowImages = {'on','off'};
defaultShowMessages = 'off';
expectedShowMessages = {'on','off'};
classes = {'uint8'};
attributes = {'size',[NaN,NaN,NaN]};
addRequired(p,'I',@(x)validateattributes(x,classes,attributes));
addRequired(p,'T');
addRequired(p,'panoramaView');
addParameter(p,'ShowImages',defaultShowImages,...
                 @(x) any(validatestring(x,expectedShowImages)));
addParameter(p,'ShowMessages',defaultShowMessages,...
                 @(x) any(validatestring(x,expectedShowMessages)));
parse(p,I,T,panoramaView,varargin{:})


% Place Images on final Preprocessed Images
Ipano = imwarp(I,T,'OutputView',panoramaView);

if strcmp(p.Results.ShowMessages,'on')
    fprintf('Image placed on Panorama!\n');
end
if strcmp(p.Results.ShowImages,'on')
    figure; imshow(Ipano);
end

end

%%
function panorama = image_stitching(I1,I2,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Inputs
% I1: Image 1 | rgb uint8 0..255
% I2: Image 2 | rgb uint8 0..255
%
% Optional Input Arguments (Name value pairs)
% 'ShowMessages' | 'on' or 'off' | default is 'off' | Displays Messages
% 'ShowImages' | 'on' or 'off' | default is 'off' | Displays Images
% 
% Outputs
% panorama: Non blended Panorama Image | rgb uint8 0..255
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;
defaultShowImages = 'off';
expectedShowImages = {'on','off'};
defaultShowMessages = 'off';
expectedShowMessages = {'on','off'};
classes = {'uint8'};
attributes = {'size',[NaN,NaN,3]};
addRequired(p,'I1',@(x)validateattributes(x,classes,attributes));
addRequired(p,'I2',@(x)validateattributes(x,classes,attributes));
addParameter(p,'ShowImages',defaultShowImages,...
                 @(x) any(validatestring(x,expectedShowImages)));
addParameter(p,'ShowMessages',defaultShowMessages,...
                 @(x) any(validatestring(x,expectedShowMessages)));
parse(p,I1,I2,varargin{:})

blender = vision.AlphaBlender('Operation', 'Binary mask', ...
    'MaskSource', 'Input port');
panorama = step(blender, I2, I1, I1(:,:,1));
panorama = uint8(panorama);

if strcmp(p.Results.ShowImages,'on')
	figure; imshow(panorama);
    titel('Resulting non blended Panorama');
end
if strcmp(p.Results.ShowMessages,'on')
    fprintf('Nonblended Panorama complete!\n');
end

end