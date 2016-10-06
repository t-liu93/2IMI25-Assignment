/*********************************************
 * OPL 12.6.3.0 Model
 * Author: Tianyu Liu(0937147) and Li Wang(0977456)
 * Creation Date: Sep 24, 2016 at 4:12:35 PM
*********************************************/
using CP;
tuple Character {
  key string name;
  string type;
}
tuple Scene {
  string name;
  {string} characterSet;
}
{string} CharacterTypes = ...;
{string} LeadingCharacters = ...;
int maxNrOfCharacters = ...;
{Scene} Scenes = ...;
{Character} Characters with type in CharacterTypes = ...;
int cardc;
execute {
  cardc = Opl.card(Characters);
  writeln("Number of Characters:", cardc);
}

dvar int assignment[ct in Characters] in 0 .. cardc-1;

dvar int NrOfActorsNeeded;

minimize
  NrOfActorsNeeded;

subject to {
  //comment following two lines to get some result, I have no idea where went wrong.
//  version 1
//  forall ( leadingc in LeadingCharacters )
//    count ( assignment, assignment[< leadingc >] ) ==1;
  
//  version 2, hardcode to test the syntex
//  count(assignment,assignment[<"Stacy">])==1;
  
//  version 3, same as version 1 in logic but runs more loops.
//  forall(c in Characters)
//    c.name in LeadingCharacters=>(count(assignment,assignment[c])==1);

//none of above works, I think the reason is that we're supposed to use an int array indexed by int in count function but what we use is an array indexed by string. 
	
//	following one works also make some sense, but I don't think it covers all the cases.
//	allDifferent( all ( c in LeadingCharacters ) assignment[< c >] )

// Solve Constraint 3
  forall ( s in Scenes )
    allDifferent ( all ( c in s.characterSet ) assignment[< c >] );
//TODO: Add more constraints

//not really cover the character type constraint
  forall ( c1, c2 in Characters )
    (assignment[c1] == assignment[c2] => c1.type == c2.type) ;

//  forall(c1, c2 in Characters)
//    (c1.type == c2.type) => (assignment[c1] == assignment[c2]);

//	forall(c1, c2 in Characters)
//	  (c1.type == c2.type) + (assignment[c1] == assignment[c2]) <= 2;
    
//    allDifferent( all (lc in LeadingCharacters) assignment[ <lc> ]);
//    forall (lc in LeadingCharacters, c in Characters)
//      assignment[ <lc> ] != assignment[c];

//Solve Constraint 4
//Version 1.0
	forall (c1 in Characters, c2 in LeadingCharacters)
//	    c1.name != c2 => assignment[c1] != assignment[ <c2> ];
		assignment[c1] == assignment[ <c2> ] => c1.name == c2;
}

//fill in from your decision variables.
int nrOfActorsOfType[ct in CharacterTypes];

//fill in from your decision variables.
{Character} CharactersPlayedByActor[i in 0 .. NrOfActorsNeeded - 1];

execute {

for(var lc in Characters){
	writeln("Number of leading characters:",lc,assignment[lc]);
}

  writeln("Actors needed: ", NrOfActorsNeeded);
  for ( var ct in CharacterTypes) {
    writeln(ct, " needed: ", nrOfActorsOfType[ct]);
  }
  for ( var i = 0; i < NrOfActorsNeeded; i++) {
    writeln("Actor ", i, " plays ", CharactersPlayedByActor[i]);
  }
}