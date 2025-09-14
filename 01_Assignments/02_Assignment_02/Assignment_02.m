% CAP6419: 3D Computer Vision
% Assignment 02: Chapter 3 of Textbook: Multiple View Geometry in Computer Vision (2nd Edition)


% In this assignment, you are expected to take your own test images and work with them. Write Matlab code to perform:

    % 1. Affine rectification of an imaged planar surface
    % 2. Metric rectification of an imaged planar surface

%% ASSIGNMENT PARAMETERS
% Submit your matlab codes and results on the test images together with a report in a
% word document explaining how your program works (i.e. the steps involved). What were the
% problems that you noticed, if any? Your report should be written like a technical paper, and
% should also include a conclusion section at the end (including your reflections and thoughts, what
% worked and what went wrong if any).
% For your convenience, I have also provided some test images and a short Matlab code for fitting
% a conic to a set of 5 or more points based on the method discussed in the class (page 31 of your
% textbook).
% Grading: 10% data collection (camera pictures, or online images), 20% coding for affine
% rectification, 20% coding for metric rectification, 30% thorough testing on several images for
% both rectifications, 20% report. Again, your report must contain the procedures, input test
% images, output images after rectification, and your conclusions and reflections on the problem
% and the results.
% ______________________________________________________________________
% Suggestion for taking test images: You may want to take a picture of the main lobby of the
% student union, with the encircled Pegasus in the middle that can be used for metric rectification.
% Make sure you can identify parallel lines and/or cross-ratios in your pictures. Also make sure that
% the pictures have enough projective distortion (i.e. taken at an angle).
% Reminder : The intersection of a line l and a conic C can be determined as follows: let m1 and
% m2 be two points on the line l, then any arbitrary point m on the line can be specified
% parametrically by m =m1 +λm2 . Point m is on the intersection of the line with the conic C, iff
% mTCm =(m1 +λm2 )T C(m1 +λm2 ) =0.
% This yields the following quadratic equation in terms of λ
% λ2 m2TCm2 2 +λ m2TCm1 + m1TC m1 0 =
% from which we get the two values λ1 and λ2 , and hence the two intersection points m1 +λ1m2 and
% m1 +λ2m2 . Note that in general a line intersects a conic at two points, which may be distinct or
% not and real or complex


clc, clearvars

