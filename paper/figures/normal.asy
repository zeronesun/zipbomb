include "common.asy";

Capsule lfh_1 = LFH(0b, 40b, "README", "$\mbox{LFH}_1$", "file data");
Capsule lfh_2 = LFH(lfh_1.end(), 40b, "Makefile", "$\mbox{LFH}_2$", "file data");
Capsule lfh_3 = LFH(lfh_2.end(), 58b, "demo.c", "$\mbox{LFH}_3$", "file data");

Capsule cdh_1 = CDH(lfh_3.end(), "README", "$\mbox{CDH}_1$");
Capsule cdh_2 = CDH(cdh_1.end(), "Makefile", "$\mbox{CDH}_2$");
Capsule cdh_3 = CDH(cdh_2.end(), "demo.c", "$\mbox{CDH}_3$");

draw_capsule(lfh_1);
draw_capsule(lfh_2);
draw_capsule(lfh_3);
draw_capsule(cdh_1);
draw_capsule(cdh_2);
draw_capsule(cdh_3);

draw_reference(cdh_1.start+42b, lfh_1.start, 1);
draw_reference(cdh_2.start+42b, lfh_2.start, 2);
draw_reference(cdh_3.start+42b, lfh_3.start, 3);

draw_span(lfh_1.start, lfh_1.end(), 1, "file 1");
draw_span(lfh_2.start, lfh_2.end(), 1, "file 2");
draw_span(lfh_3.start, lfh_3.end(), 1, "file 3");
draw_span(cdh_1.start, cdh_3.end(), 1, "central directory");
