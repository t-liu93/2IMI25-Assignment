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

dvar int assignment[Characters] in 0 .. 10;

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
forall ( leadingc in LeadingCharacters )
  count ( assignment, assignment[< leadingc >] ) ==1;

forall ( s in Scenes )
    allDifferent ( all ( c in s.characterSet ) assignment[< c >] );

forall(c1,c2 in Characters)
  assignment[c1]==assignment[c2]=>c1.type==c2.type;

}

//fill in from your decision variables.
int nrOfActorsOfType[ct in CharacterTypes];

//fill in from your decision variables.
{Character} CharactersPlayedByActor[i in 0 .. NrOfActorsNeeded - 1];

execute {
  writeln("Actors needed: ", NrOfActorsNeeded);
  for ( var ct in CharacterTypes) {
    writeln(ct, " needed: ", nrOfActorsOfType[ct]);
  }
  for ( var i = 0; i < NrOfActorsNeeded; i++) {
    writeln("Actor ", i, " plays ", CharactersPlayedByActor[i]);
  }
}
