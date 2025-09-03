% CAP6419: 3D Computer Vision
% Assignment 01: Chapter 2 of Textbook: Multiple View Geometry in Computer Vision (2nd Edition)

clc, clearvars

a=1
b=2
c=3
x=0;
y=0;


% QUESTION 01:  (10 pts.) We learned about the duality of   points and lines in the projective space  
% of  dimension  2  (P2).  Therefore,  a  3-vector [a  b  c]T  can  be  either  a  point  in  P2  or  a  line  in  P2. 
% What is the relationship between the point m ~ [a  b  c]T and the line  l ~  [a  b  c]T  ?(explain) (Hint:  
% find  the  distances  from  the  origin  to  both  m  and  l  and  try  to  see  if  you  can  identify  a relationship.)


        %ANSWER TO QUESTION 01:
        % In Projective Geometry, the point m ~ [a b c]T corresponds to the line l ~ [a b c]T. 
        % A projective point m ~ [a b c]T corresponds to the Euclidean point M : (a/c, b/c) provided c ≠ 0.
        % A projective line l ~ [a b c]T corresponds to the Euclidean line L: ax + by + c = 0

        % The distance from the origin to the line L is given by:

        origin_homogeneous = [x; y; 1];  % Origin in homogeneous coordinates (projective point)
        euclidean_origin = [x; y];  % Origin in Euclidean coordinates

        euclidean_point = [a/c; b/c];  % Convert projective point m to Euclidean coordinates

        % Distance of euclidean point from euclidean origin
        distance_from_origin_to_point = sqrt((euclidean_point(1) - euclidean_origin(1))^2 + (euclidean_point(2) - euclidean_origin(2))^2)

        % Distance from the origin to the line L
        distance_from_origin_to_line = abs(c) / sqrt(a^2 + b^2)

        % Distance from origin to projective point and distance from origin to projective line are INVERSES to each other:

        inverse_relationship = distance_from_origin_to_point * distance_from_origin_to_line % Should equal to 1





% QUESTION 02: (10 pts.)  Determine  the  point  at  infinity  (the  ideal  point)  on  the  line  l ~  [5  -7  3]T  .  
%What is the  dual line to this ideal point? What can you say about this line? What is the dual point to the line 
%at infinity? (You must show all your work.) 


        % ANSWER TO QUESTION 02:

        % In a projective plane P2, a point at infinity (the ideal point) is any point where the third homogenous coordinate is 0. To find the ideal point, we need to find the intersection of line l ~  [5  -7  3]T with the line at infinity l_inf ~ [0 0 1]T.

        % The intersection can be found by solving the system of equations given by the two lines:

        l_question_02 = [5; -7; 3]  % Line l in homogeneous coordinates
        l_inf_question_02 = [0; 0; 1]  % Line at infinity in homogeneous coordinates

        % To find the intersection point, we can use the cross product of the two lines:
        ideal_point = cross(l_question_02, l_inf_question_02)  % Ideal point in homogeneous coordinates

        % The ideal point should equal = [-7; -5; 0]
        ideal_point_expected = [-7; -5; 0];

            % Verify the result
            is_equal = isequal(ideal_point, ideal_point_expected)  % Should be true'

        % The dual line to this ideal point will have the same vector representation:

        dual_line = ideal_point

        % In projective geometry, due to duality, the ideal point and dual line will have the same representation.
        % the dual line will cross at the origin (0,0) in Euclidean Geometry
        % It's euclidean equation is: y = (5/7)x + 3/7

        %Due to the law of duality, the dual point will have the same representation of the line at infinity, therefore:
        dual_point_at_infinity = l_inf_question_02  % Dual point to the line at infinity





% QUESTION 03: (10 pts.) (Isomorphism of Incidence) Consider the two lines l1~[5, -7, 3]T and l2~[-3, -5, 2]T. 
% What is the dual point m corresponding to the line through the points dual to the lines l1 and l2?
% Show how you would find the answer and verify mathematically based on your answer in Q1. What can you say about m? (Explain)
% How does your answer to Q3 explain the answer to Q2? (Hint: Use the x and y axes as the two lines.)


        % ANSWER TO QUESTION 03:

        L_1_Question_03 = [5; -7; 3];  % Line l1 in homogeneous coordinates
        L_2_Question_03 = [-3; -5; 2];  % Line l2 in homogeneous coordinates

        % Find the dual point m corresponding to the line through the points dual to the lines l1 and l2 by doing the cross product
        dual_point_m_Question_03 = cross(L_1_Question_03, L_2_Question_03)  % Dual point in homogeneous coordinates

        expected_dual_point_m_Question_03 = [1; -19; -46];

        % Verify the result
        is_equal_question_03 = isequal(dual_point_m_Question_03, expected_dual_point_m_Question_03)  % Should be true

        % The answer to Question 3 answers Question 2 

        % Question 3 demonstrates a general method for finding the point of intersections between two lines in a projective space. The dot product is used. Question 2 is just about finding the point of intersection between a line and a line that represents infinity.





% QUESTION 04: (20 pts.) Five points in P2 uniquely define a general conic. Therefore a general conic is fully 
% specified by a symmetric 3x3 matrix C that in general has 5 d.o.f.: 
%
%        [a  b  d]
%    C ~ [b  c  e]
%        [d  e  f]
%
% As we learned in the lectures a point m~[x y 1]T is on C if mTCm = 0. If a = c and b = 0, 
% then C has only 3 d.o.f. and becomes a circle (in the usual Euclidean sense that you are familiar with). 
% For this question, you are required to write a Matlab function that would allow the user to input 
% random values for the parameters a = c, d, e, and f (with b assumed equal to zero), and would  
% output the intersection points of the circle C with the line at infinity l~[0 0 1]T. 
% 
% Experiment with many different values of the input parameter set and answer the following  
% questions: 
% What do you notice?  
% What conclusion can you draw from this experiment? 
% 
% Do you have any explanation?  
% (If not, do not worry...you will not lose points for not giving an explanation.) 


        % ANSWER TO QUESTION 04:

        % Example usage:
        % Try several random values for a, d, e, f
        disp('Intersection points for a=2, d=1, e=3, f=4:')
        disp(circle_infinity_intersection(2, 1, 3, 4))

        disp('Intersection points for a=5, d=0, e=0, f=1:')
        disp(circle_infinity_intersection(5, 0, 0, 1))

        disp('Intersection points for a=0, d=1, e=1, f=1:')
        disp(circle_infinity_intersection(0, 1, 1, 1))

        % Function to compute intersection points of a circle with the line at infinity
        function intersection_points = circle_infinity_intersection(a, d, e, f)
            % a = c, b = 0 for a circle
            % Circle matrix:
            %   [a  0  d]
            %   [0  a  e]
            %   [d  e  f]
            C = [a 0 d; 0 a e; d e f];

            % Line at infinity in homogeneous coordinates
            l_inf = [0; 0; 1];

            % Any point at infinity has the form m = [x; y; 0]
            % Plug into m' * C * m = 0:
            % [x y 0] * C * [x; y; 0] = 0
            % => [x y 0] * [a 0 d; 0 a e; d e f] * [x; y; 0]
            % => [x y 0] * [a*x; a*y; d*x + e*y]
            % => a*x^2 + a*y^2 = 0
            % => a(x^2 + y^2) = 0

            % If a ~= 0: x^2 + y^2 = 0
            % Solutions: x = t, y = i*t or x = t, y = -i*t (i = sqrt(-1)), t ≠ 0
            % If a == 0: The conic is degenerate at infinity

            if a == 0
                intersection_points = 'Degenerate: The circle is at infinity (no finite intersection)';
            else
                % Two points at infinity (complex conjugate directions)
                m1 = [1; 1i; 0];
                m2 = [1; -1i; 0];
                intersection_points = [m1, m2];
            end
        end

        % Conclusion:
        % When running the code, it seems that the intersection points are always the same points at infinity, regardless of the circle's center or radius
        % All circles in projective geometry intersect the line at infinity at the same two points: [1; 1i; 0] and [1; -1i; 0]
