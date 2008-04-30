#!/bin/bash

EXIT=0
OCAML_NODE_NAME=ocaml

# start erlang first (ensure epmd is running)
echo; echo "Test $0: Run and stop an erlang node to ensure epmd is running."
erl -sname erl_test -setcookie cookie -noshell -s init stop

echo; echo "Test $0: Run the ocaml server."
# TODO hard coded cookie "cookie" :(
./ex_node_double.byte $OCAML_NODE_NAME &
OCAML_PID=$!
sleep 0.5

echo; echo "Test $0: Run erlang node to interact with ocaml node."
erl -sname erl_test -setcookie cookie -noshell -eval "
    OcamlNode = list_to_atom(\"$OCAML_NODE_NAME@\" ++ net_adm:localhost()),
    pong = net_adm:ping(OcamlNode),

    P1 = make_ref(),
    {bytwo, OcamlNode} ! {self(), P1, 21},
    P2 = make_ref(),
    {bytwo, OcamlNode} ! {self(), P2, 12},
    
    receive {P1, 42} -> ok after 1 -> error end,
    receive {P2, 24} -> ok after 1 -> error end,
    
    ok.
" -s init stop
EXIT=$?

echo; echo "Test $0: Kill ocaml server"
kill $OCAML_PID

echo; echo "Test $0: RESULT=${EXIT} (0=ok)"
exit ${EXIT}
