# ========================================================================
# LISTING 21
#
# COPIED FROM CASEY
# ========================================================================

from math import radians, sin, cos, sqrt, asin
import time
import json

JSONFile = open('data.json')

#
# Read the input
#

StartTime = time.time()
JSONInput = json.load(JSONFile)
MidTime = time.time()

#
# Average the haversines
#

def HaversineOfDegrees(X0, Y0, X1, Y1, R):

  dY = radians(Y1 - Y0)
  dX = radians(X1 - X0)
  Y0 = radians(Y0)
  Y1 = radians(Y1)

  RootTerm = (sin(dY/2)**2) + cos(Y0)*cos(Y1)*(sin(dX/2)**2)
  Result = 2*R*asin(sqrt(RootTerm))

  return Result

EarthRadiuskm = 6371
Sum = 0
Count = 0
for Pair in JSONInput['pairs']: 
    Sum += HaversineOfDegrees(Pair['x0'], Pair['y0'], Pair['x1'], Pair['y1'], EarthRadiuskm)
    Count += 1
Average = Sum / Count
EndTime = time.time()

#
# Display the result
#

print("Result: " + str(Average))
print("Input = " + str(MidTime - StartTime) + " seconds")
print("Math = " + str(EndTime - MidTime) + " seconds")
print("Total = " + str(EndTime - StartTime) + " seconds")
print("Throughput = " + str(Count/(EndTime - StartTime)) + " haversines/second")
