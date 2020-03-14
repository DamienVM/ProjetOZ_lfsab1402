declare
fun {PartitionToTimedList Partition}
   case Partition
   of nil then nil
   [] H|T then
      local
	 fun{IsExtanded N}
	 if N == silence then false
	 else case N
	      of H|T then {IsExtanded H}
	      else
		 local Name in
		    Name = {Label N}
		    Name == note orelse Name == silence
		 end
	      end
	 end
	 end
      in
	 if {IsExtanded H} then
	    H|{PartitionToTimedList T}
	 else
	    local
	       fun {NoteToExtended Note}
		  case Note
		  of Name#Octave then
		     note(name:Name octave:Octave sharp:true duration:1.0 instrument:none)
		  [] Atom then
		     case {AtomToString Atom}
		     of [_] then
			note(name:Atom octave:4 sharp:false duration:1.0 instrument:none)
		     [] [N O] then
			note(name:{StringToAtom [N]}
			     octave:{StringToInt [O]}
			     sharp:false
			     duration:1.0
			     instrument: none)
		     else
			silence(duration:1.0)
		     end
		  end
	       end

	       fun {ChordToExtended Chord}
		  case Chord
		  of nil then nil
		  [] H|T then {NoteToExtended H}|{ChordToExtended T}
		  end
	       end

	    in
	       case H
	       of K|J then {ChordToExtended H}|{PartitionToTimedList T}
	       [] Name#Octave then {NoteToExtended H}|{PartitionToTimedList T}
	       else
		  case H
		  of transpose(semitones:S Part)then
		     false
		  [] drone(note:N Part) then
		     false
		  [] stretch(factor:F Part)then
		     local
			NP
			P = {PartitionToTimedList Part}
			fun{Stretch P F}
			   local
			      fun{StretchNote N F}
				 case N
				 of H|T then
				    local
				       fun {StretchChord C F}
					  case C
					  of nil then nil
					  [] H|T then {StretchNote N F}|{StretchChord T F}
					  end
				       end
				    in
				       {StretchChord H F}
				    end
				 elseif {Label N} == note then
				    note(name:N.name octave:N.octave sharp:N.sharp duration:(N.duration*F) instrument:N.instrument)
				 else silence(duration:(N.duration*F))
				 end
			      end

			   in
			      case P
			      of nil then nil
			      [] H|T then {StretchNote H F}|{Stretch T F}
			      end
			   end
			end
		     in
			NP={Stretch P F}
			local
			   fun{Ajouter P K}
			      case P
			      of nil then {PartitionToTimedList K}
			      [] H|T then H|{Ajouter T K}
			      end
			   end
			in
			   {Ajouter NP T}
			end			      
		     end
		     
		  [] duration(seconds:S) then
		     false
		     
		     
		  else
		     {NoteToExtended H}|{PartitionToTimedList T}
		  end
	       end
	    end
	 end
      end
   end
end

      
{Browse {PartitionToTimedList [ stretch(factor:3.0 [a a a a a]) ] }}



declare
fun{Lol A}
   case A
   of nil then b
   [] H|T then H|{Lol T}
   end
end

{Browse {Lol a|a|a|nil}|nil}
   
B
A = a|a|a|nil

