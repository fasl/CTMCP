declare
fun {Sqrt X}
   Guess= 1.0
in
   {SqrtIter Guess X}
end
fun {SqrtIter Guess X}
   if {GoodEnough Guess X} then Guess
   else
      {SqrtIter {Improve Guess X} X}
   end
end
fun {Improve Guess X}
   (Guess + X/Guess) / 2.0
end
fun {GoodEnough Guess X}
   {Abs X-Guess*Guess}/X < 0.00001
end
fun {Abs X} if X < 0.0 then ~X else X end end

{Browse {Sqrt 3.0}}

declare
local
   fun {Improve Guess X}
      (Guess + X/Guess) / 2.0
   end
   fun {GoodEnough Guess X}
      {Abs X-Guess*Guess}/X < 0.00001
   end
   fun {SqrtIter Guess X}
      if {GoodEnough Guess X} then Guess
      else
         {SqrtIter {Improve Guess X} X}
      end
   end
in
   fun {Sqrt2 X}
      Guess=1.0
   in
      {SqrtIter Guess X}
   end
end

{Browse {Sqrt2 3.0}}

declare
fun {Sqrt3 X}
   fun {SqrtIter Guess X}
      fun {Improve Guess X}
         (Guess + X/Guess) / 2.0
      end
      fun {GoodEnough Guess X}
         {Abs X-Guess*Guess}/X < 0.00001
      end
   in
      if {GoodEnough Guess X} then Guess
      else
         {SqrtIter {Improve Guess X} X}
      end
   end
   Guess=1.0
in
   {SqrtIter Guess X}
end

{Browse {Sqrt3 5.0}}

declare
fun {Sqrt4 X}
   fun {SqrtIter Guess}
      fun {Improve}
         (Guess + X/Guess) / 2.0
      end
      fun {GoodEnough}
         {Abs X-Guess*Guess}/X < 0.00001
      end
   in
      if {GoodEnough} then Guess
      else
         {SqrtIter {Improve}}
      end
   end
   Guess=1.0
in
   {SqrtIter Guess}
end

{Browse {Sqrt4 5.0}}

declare
fun {Sqrt5 X}
   fun {Improve Guess}
      (Guess + X/Guess) / 2.0
   end
   fun {GoodEnough Guess}
      {Abs X-Guess*Guess}/X < 0.00001
   end
   fun {SqrtIter Guess}
      if {GoodEnough Guess} then Guess
      else
         {SqrtIter {Improve Guess}}
      end
   end
   Guess=1.0
in
   {SqrtIter Guess}
end

{Browse {Sqrt5 5.0}}

declare
fun {Iterate S IsDone Transform}
   if {IsDone S} then S
   else S1 in
      S1 = {Transform S}
      {Iterate S1 IsDone Transform}
   end
end
fun {Sqrt6 X}
   {Iterate
    1.0
    fun {$ G} {Abs X-G*G}/X < 0.00001 end
    fun {$ G} {G + X/G} / 2.0 end}
end


{Browse {Sqrt5 6.0}}

declare
fun {Fact N}
   if N ==0 then 1
   elseif N>0 then N* {Fact N-1}
   else raise domainError end
   end
end

{Browse {Fact 10}}

declare
fun {Fact2 N}
   fun {FactIter N A}
      if N==0 then A
      elseif N>0 then {FactIter N-1 A*N}
      else raise domainError end
      end
   end
in
   {FactIter N 1}
end

{Browse {Fact2 9}}

declare
fun {Length Ls}
   case Ls
   of nil then 0
   [] _|Lr then 1+{Length Lr}
   end
end
{Browse {Length [a b c]}}

declare
fun {Append Ls Ms}
   case Ls
   of nil then Ms
   [] X|Lr then X|{Append Lr Ms}
   end
end

{Browse {Append [a b c] [d e f]}}

declare
fun {Nth Xs N}
   if N==1 then Xs.1
   elseif N>1 then {Nth Xs.2 N-1}
   end
end

{Browse {Nth [a b c d] 2}}
{Browse {Nth [a b c d] 5}}

declare
fun {SumList Xs}
   case Xs
   of nil then 0
   [] X|Xr then X+{SumList Xr}
   end
end

{Browse {SumList [1 2 3]}}

{Browse {SumList 1|foo}}

declare
fun {Reverse Xs}
   case Xs
   of nil then nil
   [] X|Xr then
      {Append {Reverse Xr} [X]}
   end
end

{Browse {Reverse [1 2 3 4]}}

declare
local
   fun {IterLength I Ys}
      case Ys
      of nil then I
      [] _|Yr then {IterLength I+1 Yr}
      end
   end
in
   fun {Length2 Xs}
      {IterLength 0 Xs}
   end
end

{Browse {Length2 [1 2 3 4]}}

declare
local
   fun {IterReverse Rs Ys}
      case Ys
      of nil then Rs
      [] Y|Yr then {IterReverse Y|Rs Yr}
      end
   end
in
   fun {Reverse2 Xs}
      {IterReverse nil Xs}
   end
end

{Browse {Reverse2 [1 2 3 4]}}