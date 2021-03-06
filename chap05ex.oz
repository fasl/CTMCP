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

declare
proc {NewPortObjects ?AddPortObject ?Call}
   Sin P={NewPort Sin}
   proc {MsgLoop S1 Procs}
      case S1
      of add(I Proc Sync)|S2 then Procs2 in
         Procs2={AdjoinAt Procs I Proc}
         Sync=unit
         {MsgLoop S2 Procs2}
      [] msg(I M)|S2 then
         try {Procs.I M} catch _ then skip end
         {MsgLoop S2 Procs}
      [] nil then skip end
   end
in
   thread {MsgLoop Sin procs} end
   proc {AddPortObject I Proc}
      Sync in
      {Send P add(I Proc Sync)}
      {Wait Sync}
   end
   proc {Call I M}
      {Send P msg(I M)}
   end
end


% 1.

declare
[QTk]={Module.link ["x-oz://system/wp/QTk.ozf"]}

declare
fun {NewProgWindow CheckMsg}
   InfoHdl See={NewCell true}
   H D=td(title:"Progress monitor"
          label(text:nil handle:InfoHdl)
          checkbutton(
             text:CheckMsg handle:H init:true
             action:proc {$} See:={H get($)} end))
in
   {{QTk.build D} show}
   proc {$ Msg}
      if @See then {Delay 50} {InfoHdl set(text:Msg)} end
   end
end


declare AddPortObject Call
{NewPortObjects AddPortObject Call}

InfoMsg={NewProgWindow "See ping-pong"}

fun {PingPongProc Other}
   proc {$ Msg}
      case Msg
      of ping(N) then
         {InfoMsg "ping("#N#")"}
         {Call Other pong(N+1)}
      [] pong(N) then
         {InfoMsg "pong("#N#")"}
         {Call Other ping(N+1)}
      end
   end
end

{AddPortObject pingobj {PingPongProc pongobj}}
{AddPortObject pongobj {PingPongProc pingobj}}
{Call pingobj ping(0)}
{Call pingobj ping(10000000)}

% https://github.com/Altech/ctmcp-answers/blob/master/Section05/exer1.mkd

% 2.

% a.

実装がそのままだと 制御装置にリフトごとの状態を複数持てるようなっていない

% b.

declare
fun {Timer}
   {NewPortObject2
    proc {$ Msg}
       case Msg of starttimer(T Pid) then
          thread {Delay T} {Send Pid stoptimer} end
       end
    end}
end

fun {Controller Init}
   Tid={Timer}
   Cid={NewPortObject Init
        fun {$ state(Motor F Lid) Msg}
           case Motor
           of running then
              case Msg
              of stoptimer then
                 {Send Lid 'at'(F)}
                 state(stopped F Lid)
              end
           [] stopped then
              case Msg
              of step(Dest) then
                 if F==Dest then
                    state(stopped F Lid)
                 elseif F<Dest then % change
                    {Send Tid starttimer(1000*(Dest-F) Cid)}
                    state(running Dest Lid)
                 else % F>Dest % change
                    {Send Tid starttimer(1000*(F-Dest) Cid)}
                    state(running Dest Lid)
                 end
              end
           end
        end}
in Cid
end

declare
fun {Floor Num Init Lifts}
   Tid={Timer}
   Fid={NewPortObject Init
        fun {$ state(Called) Msg}
           case Called
           of notcalled then Lran in
              case Msg
              of arrive(Ack) then
                 {Browse 'Lift at floor '#Num#': open doors'}
                 {Send Tid starttimer(1000 Fid)}
                 state(doorsopen(Ack))
              [] call then
                 {Browse 'Floor '#Num#': calls a lift!'}
                 Lran=Lifts.(1+{OS.rand} mod {Width Lifts})
                 {Send Lran call(Num)}
                 state(called)
              end
           [] called then
              case Msg
              of arrive(Ack) then
                 {Browse 'Lift at floor '#Num#': open doors'}
                 {Send Tid starttimer(1000 Fid)}
                 state(doorsopen(Ack))
              [] call then
                 state(called)
              end
           [] doorsopen(Ack) then
              case Msg
              of stoptimer then
                 {Browse 'Lift at floor '#Num#': close doors'}
                 Ack=unit
                 state(notcalled)
              [] arrive(A) then
                 A=Ack
                 state(doorsopen(Ack))
              [] call then
                 state(doorsopen(Ack))
              end
           end
        end}
in Fid end

declare
fun {ScheduleLast L N}
   if L\=nil andthen {List.last L}==N then L
   else {Append L [N]} end
end

fun {Lift Num Init Cid Floors}
   {NewPortObject Init
    fun {$ state(Pos Sched Moving) Msg}
       case Msg
       of call(N) then
          {Browse 'Lift '#Num#' needed at floor '#N}
          if N==Pos andthen {Not Moving} then
             {Wait {Send Floors.Pos arrive($)}}
             state(Pos Sched false)
          else Sched2 in
             Sched2={ScheduleLast Sched N}
             if {Not Moving} then
                {Send Cid step(N)} end
             state(Pos Sched2 true)
          end
       [] 'at'(NewPos) then
          {Browse 'Lift '#Num#' at floor '#NewPos}
          case Sched
          of S|Sched2 then
             if NewPos==S then % この if もなくてよいかもしれないが チェックしたほうがよいだろう
                {Wait {Send Floors.S arrive($)}}
                if Sched2==nil then
                   state(NewPos nil false)
                else
                   {Send Cid step(Sched2.1)}
                   state(NewPos Sched2 true)
                end
%             else % change
%                {Send Cid step(S)}
%                state(NewPos Sched Moving)
             end
          end
       end
    end}
end

% declare
% proc {Building FN LN ?Floors ?Lifts}
%    Lifts={MakeTuple lifts LN}
%    for I in 1..LN do Cid in
%       Cid={Controller state(stopped 1 Lifts.I)}
%       Lifts.I={Lift I state(1 nil false) Cid Floors}
%    end
%    Floors={MakeTuple floors FN}
%    for I in 1..FN do
%       Floors.I={Floor I state(notcalled) Lifts}
%    end
% end

declare
fun {LiftShaft I state(F S M) Floors}
   Cid={Controller state(stopped F Lid)}
   Lid={Lift I state(F S M) Cid Floors}
in Lid end
proc {Building FN LN ?Floors ?Lifts}
   Lifts={MakeTuple lifts LN}
   for I in 1..LN do
      Lifts.I={LiftShaft I state(1 nil false) Floors}
   end
   Floors={MakeTuple floors FN}
   for I in 1..FN do
      Floors.I={Floor I state(notcalled) Lifts}
   end
end

declare F L in
{Building 10 2 F L}
{Send F.9 call}
{Send F.10 call}
{Send L.1 call(4)}
{Send L.2 call(5)}

% 3

大変っぽいのでパス

% 4

declare
local
   proc {ZeroExit N Is}
      case Is of I|Ir then
         if N+I\=0 then {ZeroExit N+I Ir} end
      end
   end
in
   proc {NewThread P ?SubThread}
      Is Pt={NewPort Is}
   in
      proc {SubThread P}
         {Send Pt 1}
         thread
            {P} {Send Pt ~1}
         end
      end
      {SubThread P}
      {ZeroExit 0 Is}
   end
end

declare SubT
{NewThread proc {$} {Browse a} end SubT}

declare SubT
{NewThread proc {$}
              {SubT proc {$} {Browse a} end}
              {SubT proc {$} {Browse b} end}
           end SubT}


% https://github.com/Altech/ctmcp-answers/blob/master/Section05/exer4.mkd
% http://ctm-himanshu.blogspot.jp/2009/02/ch5-ex4.html

declare
local
   proc {ZeroExit N Is}
      case Is of I|Ir then
         if N+I\=0 then {ZeroExit N+I Ir}
         else % change
            {Browse 'ZeroExit Finished'}
         end
      end
   end
in
   proc {NewThread P ?SubThread}
      Is Pt={NewPort Is}
   in
      proc {SubThread P}
         thread
            {Delay 1000} % change
            {Send Pt 1} {P} {Send Pt ~1}
         end
      end
      {SubThread P}
      {ZeroExit 0 Is}
   end
end

local SubThread in
   {NewThread
    proc {$}
       {Browse 'T1 started'}
       {SubThread
        proc {$}
           {Browse 'T2 started'} {Delay 2000}
           {Browse 'T2 finished'}
        end} %T2
       {Browse 'T1 finished'}
    end
    SubThread}
   {Browse 'NewThread Finished'}
end

% 5
declare
proc {Barrier Ps}
   fun {BarrierLoop Ps L}
      case Ps of P|Pr then M in
         thread {P} M=L end
         {BarrierLoop Pr M}
      [] nil then L
      end
   end
   S={BarrierLoop Ps unit}
in
   {Wait S}
end

declare
proc {ConcFilter L F ?L2}
   Send Close
in
   {NewPortClose L2 Send Close}
   {Barrier
    {Map L
     fun {$ X}
        proc {$}
           if {F X} then {Send X} end
        end
     end}}
   {Close}
end

declare Out
{ConcFilter [5 1 2 4 0] fun {$ X} X>2 end Out}
{Show Out}
{Browse Out}

% b

declare Out
{ConcFilter [5 1 2 4 0] fun {$ X} X>2 end Out}
{Delay 1000}
{Show Out}
{Browse Out}


% c

declare Out A
{ConcFilter [5 1 A 4 0] fun {$ X} X>2 end Out}
{Delay 1000}
{Show Out}
{Browse Out}
A=3

% d.
O(n)

c でみるように ConcFilter は計算できるものは計算する

% 8

declare
fun {StreamManager OutS1 OutS2}
   F={WaitTwo OutS1 OutS2}
in
   case F#OutS1#OutS2
   of 1#(M|NewS1)#OutS2 then
      M|{StreamManager OutS2 NewS1}
   [] 2#OutS1#(M|NewS2) then
      M|{StreamManager NewS2 OutS1}
   [] 1#nil#OutS2 then
      OutS2
   [] 2#OutS1#nil then
      OutS1
   end
end

declare
fun {Replace InL A OldS NewS}
   case InL
   of B#S|L1 andthen A=B then
      OldS=S
      A#NewS|L1
   [] E|L1 then
      E|{Replace L1 A OldS NewS}
   end
end

proc {NameServer NS L}
   case NS
   of register(A S)|NS1 then
      {NameServer NS1 A#S|L}
   [] getstream(A S)|NS1 then L1 OldS NewS in
      L1={Replace L A OldS NewS}
      thread {StreamManager S NewS OldS} end
      {NameServer NS1 L1}
   [] nil then
      skip
   end
end

% NameServer 自体に名前を付けられない
