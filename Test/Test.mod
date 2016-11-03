using CP;
 
int xSize = ...;
int ySize = ...;
int nrSquares = ...;
 
range Squares = 0..nrSquares-1;

tuple squareSize {
    int xsize;
    int ysize; 
}   
 
squareSize squares[Squares] = ...;
        
dvar interval x[s in Squares] 
    in 0..xSize 
    size squares[s].xsize;
dvar interval y[s in Squares] 
    in 0..ySize 
    size squares[s].ysize;

cumulFunction rx = 
    sum(s in Squares) pulse(x[s], squares[s].ysize);
cumulFunction ry = 
    sum(s in Squares) pulse(y[s], squares[s].xsize);

int diffFrom0 = 
    min(i in Squares : 
          squares[i].xsize != squares[0].xsize ||
          squares[i].ysize != squares[0].ysize)
        i;

execute {
    cp.param.Workers = 1;
    var f = cp.factory;
    cp.setSearchPhases(f.searchPhase(x), f.searchPhase(y));
}

subject to {

    rx <= ySize;
    ry <= xSize;
         
    // Symmetry breaking.
    
    // For a pair of equal squares i and j, there is always a solution where i 
    // starts at most when j starts on the x-axis.
    
    // If a pair of equal squares i and j starts at the same time on the x-axis,
    // there is always a solution where i ends at most when j starts on the y-axis.
    // The idea is to state startAtStart(x[i], x[j]) => endBeforeStart(y[i], y[j]);
    // but you cannot use precedence constraints in a meta-constraint.   
    
    forall(ordered i,j in Squares :
            (squares[i].xsize == squares[j].xsize &&
             squares[i].ysize == squares[j].ysize)) {
        startBeforeStart(x[i], x[j]);   
        (startOf(x[i]) == startOf(x[j])) => (endOf(y[i]) <= startOf(y[j]));            
  }         
                       
            
    if (diffFrom0 < nrSquares)
        startBeforeStart(x[0], x[diffFrom0]);   
        
  //redudant constraints
    forall(ordered i, j in Squares)
        endOf(x[i]) <= startOf(x[j]) ||
        endOf(x[j]) <= startOf(x[i]) ||
        endOf(y[i]) <= startOf(y[j]) ||
        endOf(y[j]) <= startOf(y[i]);   
};

execute{
    for(var i in Squares) {
      writeln("Square ", i, " <", squares[i].xsize, ",", 
              squares[i].ysize, "> placed at (",
              x[i].start, ",", y[i].start, ") to (",
              x[i].end, ",", y[i].end, ")");  
    }      
}  
 