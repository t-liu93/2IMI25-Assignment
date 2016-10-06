/*********************************************
 * OPL 12.6.3.0 Model
 * Author: Tianyu Liu(0937147) and Li Wang(0977456)
 * Creation Date: Sep 24, 2016 at 4:12:35 PM
*********************************************/
using CP;

/* New tuple type represent characters. Use name as key. */
tuple Character {
  key string name;
  string type;
}

/* New tuple tuple represent scenes. */
tuple Scene {
  string name;
  {string} characterSet;
}

{string} CharacterTypes = ...;//Character types as string array, read from dat.
{string} LeadingCharacters = ...;//Leading characters as string array, read from dat.
int maxNrOfCharacters = ...;//A maximum number of character an actor can play, raed from dat.
{Scene} Scenes = ...;//Scenes as scene type array, read from dat.
{Character} Characters with type in CharacterTypes = ...;//Characters with type, read from dat.

int characterNumbers;//The number of characters provided by dat.

/* Calculate the number of characters using the dat. */
execute {

cardc = Opl.card(Characters);
writeln("Number of Characters:", cardc);

}

range characterRange = 0 .. characterNumbers - 1;//Range of character numbers

/* 
* Assignment represents the actors are assigned to a character.
* The value of assignment may represent the number of actors, start from 0
*/
dvar int assignment[ct in Characters] in characterRange;

dvar int numberOfActorsNeeded;//The number of actors needed

minimize
  numberOfActorsNeeded;

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

/*
* Solve constraint 3
* An actor obviously also cannot play more than one character in the same scene. 
* Implementation: In one scene, all actors with different characters are different. 
*/
	forall ( s in Scenes )
	  allDifferent ( all ( c in s.characterSet ) assignment[< c >] );
//TODO: Add more constraints

/*
* Solve constraint 5
* There are also parts for males that can only be played by men, 
* parts for females that can only be played by women, etc. 
*/
//TODO:not really cover the character type constraint
	forall ( c1, c2 in Characters )
	  (assignment[c1] == assignment[c2] => c1.type == c2.type) ;

//  forall(c1, c2 in Characters)
//    (c1.type == c2.type) => (assignment[c1] == assignment[c2]);

//	forall(c1, c2 in Characters)
//	  (c1.type == c2.type) + (assignment[c1] == assignment[c2]) <= 2;
    
//    allDifferent( all (lc in LeadingCharacters) assignment[ <lc> ]);
//    forall (lc in LeadingCharacters, c in Characters)
//      assignment[ <lc> ] != assignment[c];

/*
* Solve Constraint 4 v1.0
* There are furthermore a couple of leading characters and the actors assigned to those characters 
* cannot play any other character as that would again confuse the audience.
*/
	forall (c1 in Characters, c2 in LeadingCharacters)
//	    c1.name != c2 => assignment[c1] != assignment[ <c2> ];
		assignment[c1] == assignment[ <c2> ] => c1.name == c2;
		
//Solve Constraint 7
//Version 1.0
/*
* Solve Constraint 7 v1.0
* A final constraint is that no actor can be assigned to more than a given maximal number of characters, 
* this as assigning too many characters to an actor will again confuse the audience.
* Implementation: Iterate all assignments over all characters in the range, 
* For different characters, the same number (i.e. the same actor) shows should be less or equal than max number.
*/
	forall (c in characterRange)
	  count(all(c2 in Characters) assignment[c2], c) <= maxNrOfCharacters;
}

//fill in from your decision variables.
int nrOfActorsOfType[ct in CharacterTypes];

//fill in from your decision variables.
{Character} CharactersPlayedByActor[i in 0 .. numberOfActorsNeeded - 1];

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