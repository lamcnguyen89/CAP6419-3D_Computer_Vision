% =========================================================================
% CAP6419: 3D Computer Vision
% Assignment 03: Projective Geometry and Camera Transformations
% =========================================================================

clc, clearvars

% =========================================================================
% Question 1 (20 pts): Invariant of Two Lines and Two Points
% =========================================================================
% Using the transformation rules for points and lines, show that two lines
% l1 and l2, and two points m1 and m2 (not lying on the lines) have the 
% invariant:
%
%           I = (l1^T * m1)(l2^T * m2)
%               ─────────────────────
%               (l1^T * m2)(l2^T * m1)

% Solution for Q1:
% [Insert your proof/solution here]


% =========================================================================
% Question 2 (20 pts): Invariant of a Conic and Two Points
% =========================================================================
% Using the transformation rules for points and conics, show that a conic C
% and two points m1 and m2 (not lying on the conic) have the invariant:
%
%           I = (m1^T * C * m2)^2
%               ─────────────────────────
%               (m1^T * C * m1)(m2^T * C * m2)

% Solution for Q2:
% [Insert your proof/solution here]


% =========================================================================
% Question 3 (20 pts): Affine Camera and Parallel Lines
% =========================================================================
% Show that an affine camera (i.e., a camera with a 3x4 projection matrix P
% whose last row is [0 0 0 1]) maps parallel lines in the 3D world to 
% parallel lines in the image. Show that this is not necessarily the case
% if the camera is not affine.

% Solution for Q3:
% [Insert your proof/solution here]


% =========================================================================
% Question 4 (20 pts): Properties of Projection Matrix Columns
% =========================================================================
% Part a: Show that the first three columns of a general projective camera
%         matrix P correspond to the vanishing points along the three world
%         coordinate axes up to unknown scales, i.e.:
%         P = [p1 p2 p3 p4], where p1 = α*vx, p2 = β*vy, and p3 = γ*vz
%         
%         Hint: vx, vy, and vz are the images of infinite points 
%         [1 0 0 0]^T, [0 1 0 0]^T, and [0 0 1 0]^T, respectively.
%
% Part b: Show that the fourth column of a general projective camera matrix P
%         corresponds to the projection of the origin of the world coordinate
%         system into the image plane.

% Solution for Q4a:
% [Insert your proof/solution here]

% Solution for Q4b:
% [Insert your proof/solution here]


% =========================================================================
% Question 5 (20 pts): Orthogonality of Vanishing Points
% =========================================================================
% Let vx and vy be the vanishing points along the x and y axes, respectively.
% Prove that:
%           vx^T * ω * vy = 0
% where ω = K^(-T) * K^(-1).

% Solution for Q5:
% [Insert your proof/solution here]
