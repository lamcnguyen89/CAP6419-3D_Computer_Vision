% =========================================================================
% CAP6419: 3D Computer Vision
% Assignment 03: Chapter 2 of Textbook: Multiple View Geometry in Computer Vision (2nd Edition)
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
% 
% In projective geometry, a transformation (homography) is represented by a 
% non-singular 3×3 matrix H. The transformation rules are:
%   - For a point m:  m' = H*m
%   - For a line l:   l' = H^(-T)*l  (where H^(-T) = (H^(-1))^T)
% 
% The incidence relationship between a line and a point is given by l^T*m = 0.
% Since m1 and m2 do not lie on l1 and l2, the terms l_i^T*m_j are non-zero.
% 
% Consider the numerator term l1^T*m1 after transformation:
% 
%   (l1')^T * m1' = (H^(-T)*l1)^T * (H*m1)
%                 = l1^T * (H^(-T))^T * H * m1
%                 = l1^T * H^(-1) * H * m1
%                 = l1^T * I * m1
%                 = l1^T * m1
% 
% Since each scalar term l^T*m is invariant under projective transformation H,
% the ratio of four such terms must also be invariant.
% 
% Let I' be the invariant after transformation:
% 
%   I' = (l1'^T * m1') * (l2'^T * m2')
%        ─────────────────────────────
%        (l1'^T * m2') * (l2'^T * m1')
% 
% Substituting the invariant relationship for each term:
% 
%   I' = (l1^T * m1) * (l2^T * m2)
%        ─────────────────────────  = I
%        (l1^T * m2) * (l2^T * m1)
% 
% Therefore, the expression I is a projective invariant.


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
% 
% The transformation rules for points and conics are:
%   - For a point m:  m' = H*m
%   - For a conic C:  C' = H^(-T)*C*H^(-1)
% 
% Consider the term m1^T*C*m2. After transformation, the corresponding term is:
% 
%   m1'^T * C' * m2' = (H*m1)^T * (H^(-T)*C*H^(-1)) * (H*m2)
%                     = m1^T * H^T * H^(-T) * C * H^(-1) * H * m2
%                     = m1^T * (H^T * H^(-T)) * C * (H^(-1) * H) * m2
% 
% Since H^T * H^(-T) = I and H^(-1) * H = I:
% 
%   m1'^T * C' * m2' = m1^T * I * C * I * m2
%                     = m1^T * C * m2
% 
% The scalar term m_i^T * C * m_j is invariant under projective transformation.
% 
% Since the numerator and denominator are products of terms that are 
% individually invariant, the ratio I must also be invariant:
% 
%   I' = (m1'^T * C' * m2')^2
%        ─────────────────────────────────────
%        (m1'^T * C' * m1') * (m2'^T * C' * m2')
% 
% Substituting the invariant relationship for each term:
% 
%   I' = (m1^T * C * m2)^2
%        ─────────────────────────────── = I
%        (m1^T * C * m1) * (m2^T * C * m2)
% 
% Therefore, the expression I is a projective invariant.



% =========================================================================
% Question 3 (20 pts): Affine Camera and Parallel Lines
% =========================================================================
% Show that an affine camera (i.e., a camera with a 3x4 projection matrix P
% whose last row is [0 0 0 1]) maps parallel lines in the 3D world to 
% parallel lines in the image. Show that this is not necessarily the case
% if the camera is not affine.

% Solution for Q3:

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

% Consider two parallel lines L1 and L2 in 3D space.
% 
% Key concepts:
%   - Parallel lines intersect at a point at infinity, M_inf
%   - In homogeneous coordinates, points at infinity have the form:
%     M_inf = [d^T  0]^T
%   - where d is the common direction vector for the parallel lines

% The image projection of the point at infinity M_inf is:
%
%     m_inf = P_A * M_inf = [M  t] * [d]  = [M*d]
%                           [0T 1]   [0]    [ 0 ]
%
% The image point m_inf is a point at infinity in the image plane
% (since its last homogeneous coordinate is 0).

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

% A general projective camera has a matrix P where the last row is NOT [0 0 0 1].
%
%     P = [M     t  ]
%         [r3^T     ]
%
% where r3^T = [p31 p32 p33 p34] is generally non-zero.

% The projection of the point at infinity M_inf = [d^T 0]^T is:
%
%     m_inf = P * M_inf = [M   ] * [d]  = [M*d     ]
%                         [r3^T]   [0]    [r3^T * d]
%
% Since r3^T = [p31 p32 p33 p34] is generally non-zero, 
% the last component r3^T * d = p31*dx + p32*dy + p33*dz is generally non-zero.

% If the last component (r3^T * d) is non-zero, then m_inf is a FINITE point 
% in the image plane. This finite point is called the VANISHING POINT for 
% direction d.
%
% Since different parallel lines L1 and L2 share the same vanishing point,
% their images l1 and l2 will intersect at this finite vanishing point.
%
% Lines that intersect at a finite point are NOT parallel in the image.

% For a general projective camera, parallel lines in 3D do NOT necessarily 
% map to parallel lines in the image. Instead, they map to image lines that 
% intersect at a vanishing point (finite point in the image).
%
% This is why we observe perspective effects in real cameras, where parallel
% lines (like railroad tracks) appear to converge to a point in the distance.

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
%
% The general projective camera matrix is P = [p1 p2 p3 p4], where p_i are 
% 3×1 column vectors. The projection equation is m ~ P*M.

% Solution for Q4a:
% 
% The general projective camera matrix is P = [p1 p2 p3 p4], where p_i are 
% 3×1 column vectors. The projection equation is m ~ P*M.
%
% The vanishing point v_d for a direction d is the image of the point at 
% infinity M_inf = [d^T 0]^T.
%
% The points at infinity along the world coordinate axes X,Y,Z are:
%   M_x^inf = [1 0 0 0]^T
%   M_y^inf = [0 1 0 0]^T  
%   M_z^inf = [0 0 1 0]^T
%
% The image of M_x^inf (the vanishing point v_x) is:
%   v_x ~ P * M_x^inf = [p1 p2 p3 p4] * [1; 0; 0; 0] = p1
%
% This means p1 is proportional to v_x, so p1 = α*v_x for some scale α.
%
% The image of M_y^inf (the vanishing point v_y) is:
%   v_y ~ P * M_y^inf = [p1 p2 p3 p4] * [0; 1; 0; 0] = p2
%
% This means p2 is proportional to v_y, so p2 = β*v_y for some scale β.
%
% The image of M_z^inf (the vanishing point v_z) is:
%   v_z ~ P * M_z^inf = [p1 p2 p3 p4] * [0; 0; 1; 0] = p3
%
% This means p3 is proportional to v_z, so p3 = γ*v_z for some scale γ.
%
% Thus, the first three columns of P correspond to the vanishing points 
% along the three world coordinate axes up to unknown scales.


% Solution for Q4b:
%
% The origin of the world coordinate system is the 3D point M_O = [0 0 0]^T, 
% which in homogeneous coordinates is M_O^h = [0 0 0 1]^T.
%
% The image projection of the world origin is:
%   m_O ~ P * M_O^h = [p_1 p_2 p_3 p_4] * [0; 0; 0; 1] = p_4
%
% Thus, the fourth column of a general projective camera matrix P corresponds 
% to the projection of the origin of the world coordinate system into the 
% image plane (up to a scale factor).

% =========================================================================
% Question 5 (20 pts): Orthogonality of Vanishing Points
% =========================================================================
% Let vx and vy be the vanishing points along the x and y axes, respectively.
% Prove that:
%           vx^T * ω * vy = 0
% where ω = K^(-T) * K^(-1).


% Solution for Q5:
%
% The vanishing point v_d for a world line with direction d is the image of 
% the point at infinity:
%   v_d ~ P * [d; 0]
%
% For a metric camera, the projection matrix can be decomposed as P = K[R|t], 
% where K is the intrinsic matrix, R is the rotation matrix, and t is the 
% translation vector.
%
% The vanishing points for the X and Y axes are:
%   v_x ~ P * [1 0 0 0]^T = K * R * [1 0 0]^T = K * r_1
%   v_y ~ P * [0 1 0 0]^T = K * R * [0 1 0]^T = K * r_2
%
% where r_1 and r_2 are the first and second columns of the rotation matrix R.
%
% The orthogonality condition in the image is defined by the absolute dual 
% conic ω = K^(-T) * K^(-1). Two image directions v_a and v_b are orthogonal 
% in the world if and only if:
%   v_a^T * ω * v_b = 0
%
% For the X and Y axes, the world directions [1 0 0]^T and [0 1 0]^T are 
% orthogonal. We need to prove v_x^T * ω * v_y = 0.
%
% Substitute the expressions for v_x, v_y, and ω:
%   v_x^T * ω * v_y = (K * r_1)^T * (K^(-T) * K^(-1)) * (K * r_2)
%                    = r_1^T * K^T * K^(-T) * K^(-1) * K * r_2
%
% Since K^T * K^(-T) = I and K^(-1) * K = I:
%   v_x^T * ω * v_y = r_1^T * I * I * r_2
%                    = r_1^T * r_2
%
% Since R is a rotation matrix, its columns (r_1, r_2, r_3) are orthonormal 
% vectors. The dot product of orthogonal vectors r_1 and r_2 is zero:
%   r_1^T * r_2 = 0
%
% Therefore:
%   v_x^T * ω * v_y = 0
%
% The vanishing points v_x and v_y satisfy the orthogonality condition 
% defined by ω.


% =========================================================================

