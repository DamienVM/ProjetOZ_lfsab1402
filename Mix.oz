declare
fun{Hauteur N}
   case N
   of note(name:Name octave:O sharp:S duration:D instrument:I) then
      12*(O-4)+{NoteToNumb N}-10
   end
end

fun{Add L1 L2}
   case L1
   of nil then nil
   [] H|T then H+L2.1|{Add T L2.2}
   end
end

fun {NoteToEchantillon N}
   case N
   of H|T then
      local
	 fun{ChordToEchantillon C}
	    case C
	    of H|nil then {NoteToEchantillon H}
	    [] H|T then
	       {Add {NoteToEchantillon H} {ChordToEchantillon T}}
	    end
	 end
      in
	 {ChordToEchantillon N}
      end
   [] note(name:Name octave:O sharp:S duration:D instrument:I) then
      local
	 I = {FloatToInt D*44100.0}
	 H = {IntToFloat {Hauteur N}}
	 F = {Pow 2.0 (H/12.0)} *440.0
      in
	 {CreateEchantillon I F nil}
      end
   [] silence(duration:D) then
      local
	 I = {FloatToInt D*44100.0}
      in
	 {CreateEchantillon I 0.0 nil}
      end
   end
end

fun{CreateEchantillon I Freq Echantillon}
   if I == 0 then
      Echantillon
   elseif Freq == 0.0 then
       {CreateEchantillon I-1 Freq 0.0|Echantillon}
   else
      local
	 E = 0.5*{Sin (2.0*3.14159265359*Freq*({IntToFloat I}/44100.0))}
      in
	 {CreateEchantillon I-1 Freq E|Echantillon}
      end
   end
end

fun{Assembler H T}
   case H
   of nil then T
   [] K|J then K|{Assembler J T}
   end
end

fun{Echantillon Part}
   case Part
   of nil then nil
   [] H|T then {Assembler {NoteToEchantillon H} {Echantillon T}}
   end
end


 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
declare
fun{Mix P2T Music}
   case Music
   of nil then nil
   [] H|T then
      local
	 fun {Ajouter P K}
	    case P
	    of nil then {Mix P2T K}
	    [] H|T then H|{Ajouter T K}
	    end
	 end
      in
	 case H
	 of samples(Sample)then
	    {Ajouter Sample T}
	 [] partition(Part)then
	    local
	       NP = {P2T Part}
	    in
	       {Ajouter {Echantillon NP} T}
	    end
	 end
      end
   end
end

