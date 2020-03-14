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

      NumberToNote = numbertonotes(0:note(name:b sharp:false)
			     1: note(name:c sharp:false)
			     2: note(name:c sharp:true)
			     3: note(name:d sharp:false)
			     4: note(name:d sharp:true)
			     5: note(name:e sharp:false)
			     6: note(name:f sharp:false)
			     7: note(name:f sharp:true)
			     8: note(name:g sharp:false)
			     9: note(name:g sharp:true)
			     10:note(name:a sharp:false)
			     11:note(name:a sharp:true)
			     12:note(name:b sharp:false))

      fun{NoteToNumb N}
	 local
	    S = if N.sharp then 1 else 0 end
	    Name = N.name
	 in
	    if Name == c then 1+S
	    elseif Name == d then 3+S
	    elseif Name == e then 5
	    elseif Name == f then 6+S
	    elseif Name == g then 8+S
	    elseif Name == a then 10+S
	    else 12
	    end
	 end
      end

      fun{TransNote N S}
	 local NN NO NNumb Pas
	 in
	    Pas = {NoteToNumb N}+S
	    NO = N.octave+( (Pas-1) div 12)
	    NN = NumberToNote.(Pas mod 12 )
	    note(name:NN.name sharp:NN.sharp octave:NO duration:N.duration instrument:N.instrument)
	 end
      end

      fun{TransChord C S}
	 case C
	 of nil then nil
	 [] H|T then {TransNote H S}|{TransChord T S}
	 end
      end

      fun {Trans P S}
	 case P
	 of nil then nil
	 [] H|T then
	    case H
	    of note then{TransNote H S}|{Trans T S}
	    [] K|J then {TransChord H S}|{Trans T S}
	    else H|{Trans T S}
	    end
	 end
      end

      
   in
      case Partition
      of nil then nil
      [] H|T then
	 {Browse 2}
	 if {IsExtanded H} then
	    H|{PartitionToTimedList T}
	 else case H
	      of K|J then {Browse 6} {ChordToExtended H}|{PartitionToTimedList T}
	      [] Name#Octave then {NoteToExtended H}|{PartitionToTimedList T}
	      [] Transpose then
		 {Browse 9}
		 local
		    P = {PartitionToTimedList H.1}
		    {Browse P}
		    S = H.semitones
		    {Browse S} {Browse {Trans P S}} 
		 in
		    {Trans P S}|{PartitionToTimedList T}
		 end
	      [] Atom then {Browse 7} {NoteToExtended H}|{PartitionToTimedList T}
	      end
	 end
      end
   end
end

{Browse {PartitionToTimedList [ a#4 transpose([a#4 a#4] semitones:1)] }}