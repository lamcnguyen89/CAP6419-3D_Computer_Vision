%% AFFINE CAMERA AND PARALLEL LINES ANALYSIS
% This file contains theoretical analysis of how affine and projective cameras
% handle parallel lines in 3D space and their projections to image space.

%% AFFINE CAMERA PROJECTION MATRIX
% An affine camera has a projection matrix P_A with the form:
%
%     P_A = [p11  p12  p13  p14]   =  [M  t]
%           [p21  p22  p23  p24]      [0T 1]
%           [ 0    0    0    1 ]
%
% where:
%   - M is a 2x3 matrix (linear transformation part)
%   - t is a 2x1 vector (translation part)
%   - 0T is the 1x3 zero vector [0 0 0]

%% PARALLEL LINES IN 3D SPACE
% Consider two parallel lines L1 and L2 in 3D space.
% 
% Key concepts:
%   - Parallel lines intersect at a point at infinity, M_inf
%   - In homogeneous coordinates, points at infinity have the form:
%     M_inf = [d^T  0]^T
%   - where d is the common direction vector for the parallel lines

%% PROJECTION OF POINT AT INFINITY UNDER AFFINE CAMERA
% The image projection of the point at infinity M_inf is:
%
%     m_inf = P_A * M_inf = [M  t] * [d]  = [M*d]
%                           [0T 1]   [0]    [ 0 ]
%
% The image point m_inf is a point at infinity in the image plane
% (since its last homogeneous coordinate is 0).

%% KEY PROPERTY OF AFFINE CAMERAS
% Two image lines are parallel if and only if they intersect at a point at infinity.
%
% Since m_inf depends only on:
%   - The direction vector d
%   - NOT on the specific line position
%   - NOT on the translational component t of the camera matrix
%
% Both parallel lines L1 and L2 will project to image lines that intersect
% at the same point at infinity, m_inf.
%
% CONCLUSION: An affine camera maps parallel lines in the 3D world 
%             to parallel lines in the image.

%% NON-AFFINE (GENERAL PROJECTIVE) CAMERA
% A general projective camera has a matrix P where the last row is NOT [0 0 0 1].
%
%     P = [M     t  ]
%         [r3^T     ]
%
% where r3^T = [p31 p32 p33 p34] is generally non-zero.

%% PROJECTION UNDER GENERAL PROJECTIVE CAMERA
% The projection of the point at infinity M_inf = [d^T 0]^T is:
%
%     m_inf = P * M_inf = [M   ] * [d]  = [M*d     ]
%                         [r3^T]   [0]    [r3^T * d]
%
% Since r3^T = [p31 p32 p33 p34] is generally non-zero, 
% the last component r3^T * d = p31*dx + p32*dy + p33*dz is generally non-zero.

%% VANISHING POINTS IN PROJECTIVE CAMERAS
% If the last component (r3^T * d) is non-zero, then m_inf is a FINITE point 
% in the image plane. This finite point is called the VANISHING POINT for 
% direction d.
%
% Since different parallel lines L1 and L2 share the same vanishing point,
% their images l1 and l2 will intersect at this finite vanishing point.
%
% Lines that intersect at a finite point are NOT parallel in the image.

%% CONCLUSION FOR PROJECTIVE CAMERAS
% For a general projective camera, parallel lines in 3D do NOT necessarily 
% map to parallel lines in the image. Instead, they map to image lines that 
% intersect at a vanishing point (finite point in the image).
%
% This is why we observe perspective effects in real cameras, where parallel
% lines (like railroad tracks) appear to converge to a point in the distance.

%% SUMMARY
% AFFINE CAMERA:     Parallel 3D lines → Parallel image lines
% PROJECTIVE CAMERA: Parallel 3D lines → Converging image lines (vanishing point)