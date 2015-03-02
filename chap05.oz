% 5.1

declare S P in
{NewPort S P}
{Browse S}
{Send P a}
{Send P b}

% 5.2

declare P in
local S in
   {NewPort S P}
   thread {ForAll S Browse} end
end
{Send P hi}

% 5.2.1

declare
fun {NewPortObject Init Fun}
   Sin Sout in
   thread {FoldL Sin Fun Init Sout} end
   {NewPort Sin}
end

declare
fun {NewPortObject2 Proc}
   Sin in
   thread for Msg in Sin do {Proc Msg} end end
   {NewPort Sin}
end

% 5.2.2

declare
fun {Player Others}
   {NewPortObject2
    proc {$ Msg}
       case Msg of ball then
          Ran={OS.rand} mod {Width Others}+1
       in
          {Delay 1000}
          % {Browse a}
          {Send Others.Ran ball}
       end
    end}
end

declare P1 P2 P3
P1={Player others(P2 P3)}
P2={Player others(P1 P3)}
P3={Player others(P1 P2)}

{Send P1 ball}
