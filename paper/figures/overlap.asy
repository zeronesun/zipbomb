include "common.asy";

Capsule lfh = LFH(0b, 52b, "A", "$\mbox{LFH}_1$", "kernel");

Capsule cdh_1 = CDH(lfh.end(), "A", "$\mbox{CDH}_1$");
Capsule cdh_2 = CDH(cdh_1.end(), "B", "$\mbox{CDH}_2$");
Capsule cdh_n1 = CDH(cdh_2.end() + 16b, "Y", "$\mbox{CDH}_{N-1}$");
Capsule cdh_n = CDH(cdh_n1.end(), "Z", "$\mbox{CDH}_N$");

draw_capsule(lfh);
draw_capsule(cdh_1);
draw_capsule(cdh_2);
label(baseline("$\cdots$"), ((cdh_2.end()+cdh_n1.start)/2, ht/2));
draw_capsule(cdh_n1);
draw_capsule(cdh_n);

draw_reference(cdh_1.start+42b, lfh.start, 1);
draw_reference(cdh_2.start+42b, lfh.start, 2, false);
draw_reference(cdh_n1.start+42b, lfh.start, 4, false);
draw_reference(cdh_n.start+42b, lfh.start, 5, false);

draw_span(lfh.start, lfh.end(), 1, "file 1");
draw_span(lfh.start, lfh.end(), 2, "file 2");
draw_span(lfh.start, lfh.end(), 3, "$\cdots$", false);
draw_span(lfh.start, lfh.end(), 4, "file $N-1$");
draw_span(lfh.start, lfh.end(), 5, "file $N$");
draw_span(cdh_1.start, cdh_n.end(), 1, "central directory");
