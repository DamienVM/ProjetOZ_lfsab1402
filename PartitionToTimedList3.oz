declare
fun {PartitionToTimedList Partition}
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

      fun {IsExtanded N}
	 case N
	 of Atom then false
	 [] silence then true
	 [] note then true
	 [] H|T then {IsExtanded H}
	 else false
	 end
      end

      
   in
      case Partition
      of nil then nil
      [] H|T then
	 if {IsExtanded H} then
	    H|{PartitionToTimedList T}
	 else case H
	      of K|J then {ChordToExtended H}|{PartitionToTimedList T}
	      [] Atom then {NoteToExtended H}|{PartitionToTimedList T}
	      [] Name#Octave then {NoteToExtended H}|{PartitionToTimedList T}
	      end
	 end
      end
   end
end

{Browse {PartitionToTimedList [silence a#5 a a2 [b c]]}}