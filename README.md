# 3DRangeTree

Delphi implementation of 3D range search tree -> (see T3DRangeTree in RangeTree3D_u.pas)
Based on the ideas of session 3 and 4 of the course 6.851 MIT OpenWare

https://ocw.mit.edu/courses/electrical-engineering-and-computer-science/6-851-advanced-data-structures-spring-2012/

OVERVIEW:
The Data structure (DS) is designed for solving the problem of given a set S of 3D points find the subset Sm that
lies inside an axis aligned box [a1,a2]x[b1,b2]x[c1,c2]. Fast report queries O(|Sm| + log |S|) are expected.
The DS is validated in RangeTree3DForm_u.pas, and an executable of the project is available under the name
                                             
                                             RangeTree3DForm_prjct

Further descriptions can be found in the corresponding units.

CONTENTS:
RangeTree3DForm_u.pas  
RangeTree3DForm_u.dfm
RangeTree3D_u.pas       
QuarterRangeSearch_u.pas 
_3D.pas                  
_3DDefinitions.pas
RangeTree3DForm_prjct        
PointsFile_NumericalError.txt      
