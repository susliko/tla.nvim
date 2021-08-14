---- MODULE simple ----

EXTENDS TLC, Integers

(* --algorithm simple
variables alice_account = 10, bob_account = 10, money = 5;
begin
A: alice_account := alice_account - money;
B: bob_account := bob_account + money;
end algorithm; *)

\* BEGIN TRANSLATION (chksum(pcal) = "eab4de28" /\ chksum(tla) = "39fadbe7")
VARIABLES alice_account, bob_account, money, pc

vars == << alice_account, bob_account, money, pc >>

Init == (* Global variables *)
        /\ alice_account = 10
        /\ bob_account = 10
        /\ money = 5
        /\ pc = "A"

A == /\ pc = "A"
     /\ alice_account' = alice_account - money
     /\ pc' = "B"
     /\ UNCHANGED << bob_account, money >>

B == /\ pc = "B"
     /\ bob_account' = bob_account + money
     /\ pc' = "Done"
     /\ UNCHANGED << alice_account, money >>

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == A \/ B
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 
====
