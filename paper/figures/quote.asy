include "common.asy";

pen quotepen = springgreen;

Capsule lfh_1 = LFH(0b, 20b, "A", "$\mbox{LFH}_1$");
Capsule lfh_2 = LFH(lfh_1.start+lfh_1.header+5b, 40b, "B", "$\mbox{LFH}_2$");
Capsule lfh_n1 = LFH(lfh_2.start+lfh_2.header+16b, 20b, "Y", "$\mbox{LFH}_{N-1}$");
Capsule lfh_n = LFH(lfh_n1.start+lfh_n1.header+5b, 52b, "Z", "$\mbox{LFH}_N$", "kernel");
lfh_1.bodypen = quotepen;
lfh_2.bodypen = quotepen;
lfh_n1.bodypen = quotepen;

Capsule cdh_1 = CDH(lfh_n.end(), "A", "$\mbox{CDH}_1$");
Capsule cdh_2 = CDH(cdh_1.end(), "B", "$\mbox{CDH}_2$");
Capsule cdh_n1 = CDH(cdh_2.end() + 16b, "Y", "$\mbox{CDH}_{N-1}$");
Capsule cdh_n = CDH(cdh_n1.end(), "Z", "$\mbox{CDH}_N$");

draw_capsule(lfh_1);
draw_capsule(lfh_2);
label(baseline("$\cdots$"), ((lfh_2.start+lfh_2.header+lfh_n1.start)/2, ht/2));
draw_capsule(lfh_n1);
draw_capsule(lfh_n);
draw_capsule(cdh_1);
draw_capsule(cdh_2);
label(baseline("$\cdots$"), ((cdh_2.end()+cdh_n1.start)/2, ht/2));
draw_capsule(cdh_n1);
draw_capsule(cdh_n);

draw_reference(cdh_1.start+42b, lfh_1.start, 1);
draw_reference(cdh_2.start+42b, lfh_2.start, 2);
draw_reference(cdh_n1.start+42b, lfh_n1.start, 4);
draw_reference(cdh_n.start+42b, lfh_n.start, 5);

draw_span(lfh_1.start, lfh_n.end(), 1, "file 1");
draw_span(lfh_2.start, lfh_n.end(), 2, "file 2");
draw_span((lfh_2.start+lfh_n1.start)/2, lfh_n.end(), 3, "$\cdots$", false);
draw_span(lfh_n1.start, lfh_n.end(), 4, "file $N-1$");
draw_span(lfh_n.start, lfh_n.end(), 5, "file $N$");
draw_span(cdh_1.start, cdh_n.end(), 1, "central directory");
