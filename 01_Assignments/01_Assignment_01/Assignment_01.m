% CAP6419: 3D Computer Vision
% Assignment 01: Chapter 

clc, clearvars

a=1
b=2
c=3


% QUESTION 01:  (10 pts.) We learned about the duality of   points and lines in the projective space  
% of  dimension  2  (P2).  Therefore,  a  3-vector [a  b  c]T  can  be  either  a  point  in  P2  or  a  line  in  P2. 
% What is the relationship between the point m ~ [a  b  c]T and the line  l ~  [a  b  c]T  ?(explain) (Hint:  
% find  the  distances  from  the  origin  to  both  m  and  l  and  try  to  see  if  you  can  identify  a relationship.)






% QUESTION 02: (10 pts.)  Determine  the  point  at  infinity  (the  ideal  point)  on  the  line  l ~  [5  -7  3]T  .  What is the 
%dual line to this ideal point? What can you say about this line? What is the dual point to the line 
%at infinity? (You must show all your work.) 






% QUESTION 03: (10 pts.) (Isomorphism of Incidence) Consider the two lines l1~[5, -7, 3]T and
% l2~[2, 5, -3]T. What is the dual point m corresponding to the line through the points dual to
% the lines l1 and l2? Show how you would find the answer and verify mathematically based on
% your answer in Q1. What can you say about m? (Explain)
% How does your answer to Q3 explain the answer to Q2? (Hint: Use the x and y axes as the two
% lines.)





% QUESTION 04: (20 pts.) Five points in P2 uniquely define a general conic. Therefore a general conic is fully 
% specified by a symmetric 3x3 matrix C that in general has 5 d.o.f.: 
%
%        [a  b  d]
%    C ~ [b  c  e]
%        [d  e  f]
%
% As we learned in the lectures a point m~[x y 1]T is on C iff mTCm = 0. If a = c and b = 0, 
% then C has only 3 d.o.f. and becomes a circle (in the usual Euclidean sense that you are familiar 
% with). 
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


