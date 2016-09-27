/*********************************************
 * OPL 12.6.3.0 Model
 * Author: liuti
 * Creation Date: Sep 24, 2016 at 4:12:35 PM
*********************************************/
using CP;
tuple Character {
  key string name;
  string type;
}
tuple Scene {
  key string name;
  {string} characterSet;
}
{string} CharacterTypes = ...;
{string} LeadingCharacters = ...;
int maxNrOfCharacters = ...;
{Scene} Scenes = ...;
{Character} Characters with type in CharacterTypes = ...;

dvar int assignment[ct in Characters] in 0 .. 10;

dvar int NrOfActorsNeeded;
//execute {
//  var cardc = Opl.card(Characters);
//  writeln("Number of Characters:", cardc);
//  for ( var i = 0; i < cardc; i++) {
//    var c = Characters[i];
//    writeln(c.name, c.type);
//  }
//}
minimize
  NrOfActorsNeeded;

subject to {
  //comment following two lines to get some result, I have no idea where went wrong.
//  version 1
  //forall ( leadingc in LeadingCharacters )
  //  count ( assignment, assignment[< leadingc >] ) ==1;
  
//  version 2, hardcode to test the syntex
  //count(assignment,assignment[<"Stacy">])==1;
  
//  version 3, same as version 1 in logic but runs more loops.
//  forall(c in Characters)
//    c.name in LeadingCharacters=>(count(assignment,assignment[c])==1);

//none of above works
	
//	following one works also make some sense, but I don't think it covers all the cases.
	allDifferent( all ( c in LeadingCharacters ) assignment[< c >] );

  forall ( s in Scenes )
    allDifferent ( all ( c in s.characterSet ) assignment[< c >] );

  forall ( c1, c2 in Characters )
    assignment[c1] == assignment[c2] => c1.type == c2.type;

  //forall(c1,c2 in Characters)
  //  c1.type!=c2.type=>assignment[c1]!=assignment[c2];
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