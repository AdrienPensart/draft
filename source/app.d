import std.stdio;
import std.concurrency;
import std.uuid;
import std.random;
import std.range;
import core.time;
import core.thread;
import jin.go;
import nanomsg.bindings;
import nanomsg.wrap;
import std.conv;

// discovery
// heartbeat

void main()
{
    auto s = new Thread({
        //auto surveyor = NanoSocket(NanoSocket.Protocol.surveyor, BindTo("tcp://localhost:13248"));
        auto publisher = NanoSocket(NanoSocket.Protocol.publish, BindTo("tcp://localhost:13248"));

        // let clients connect
        sleep(1000.msecs);
        //writeln("server getting some stats...", nn_strerror(-11));
        //auto val = surveyor.statistics(NN_STAT_CURRENT_CONNECTIONS);
        //writeln("server has connected clients: ", val);

        surveyor.setOption(NanoSocket.Option.surveyorDeadlineMs, 1000);
        while(true)
        {
            auto sent = surveyor.send("heartbeat");
            try
            {
                while(true)
                {
                    auto data = surveyor.receive();
                    writeln("server receive: ", cast(string)data);
                    sleep(300.msecs);
                }
            }
            catch(Exception e)
            {
                writeln(e.msg);
            }
        }
    }).start();

    sleep(3.seconds);

    Thread[] rs;
    foreach( _ ; iota(5))
    {
        auto id = _;
        writeln("starting client thread ", id);
        auto r = new Thread({
            auto respondent = NanoSocket(NanoSocket.Protocol.respondent, ConnectTo("tcp://localhost:13248"));
            //respondent.setOption(NanoSocket.Option.receiveTimeoutMs, 1500);
            while(true)
            {
                auto data = respondent.receive();
                writeln("client receive: ", cast(string)data);
                respondent.send(to!string(id)~" : "~randomUUID().toString());
            }
        }).start();
        rs ~= r;
    }

    foreach(r; rs)
    {
        writeln("waiting for client");
        r.join();
    }
    writeln("waiting for server");
    s.join();
}

//enum State
//{
//    Follower, // default
//    Candidate,
//    Leader
//}
//
//enum HeartbeatTimeout = 5000;
//
//class Log
//{
//    int value;
//    MonoTime epoch;
//}
//
//class Node
//{
//    this()
//    {
//        id = randomUUID();
//        writeln("Creating node ", id);
//        surveyor = NanoSocket(NanoSocket.Protocol.surveyor, BindTo("tcp://localhost:13248"));
//        respondent = NanoSocket(NanoSocket.Protocol.respondent, ConnectTo("tcp://localhost:13248"));
//    }
//    NanoSocket surveyor;
//    NanoSocket respondent;
//    UUID id;
//    State state;
//}
//
//static void waitHeartbeat(int timeout)
//{
//    foreach( _ ; iota(0, timeout, 100))
//    {
//        writeln("sleeping for ", _, "ms");
//        sleep( _.msecs );
//    }
//}
//
//void main()
//{
//    auto node = new Node;
//    while(true)
//    {
//        final switch(node.state) with (State)
//        {
//            case Follower:
//                auto timeout = uniform(HeartbeatTimeout, HeartbeatTimeout*2);
//                writeln(node.id, " is a follower waiting heartbeat for ", timeout, "ms");
//                go!waitHeartbeat(timeout);
//                break;
//            case Candidate:
//                writeln(node.id, " is a candidate");
//                node.state = State.Follower;
//                break;
//            case Leader:
//                writeln(node.id, " is a leader");
//                node.state = State.Follower;
//                break;
//        }
//        sleep(350.msecs);
//    }
//}
//
