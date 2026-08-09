size(7inch);
fixedscaling((-1mm, 0), (183mm, 1mm));

real b = 0.45mm;
real ht = 10mm;
real sp = 0.4b;
real tiersp = ht/5;
real tierradius = ht/8;
real spansp = ht/2.5;
real capsuleradius = 2b;

pen filenamepen = Helvetica() + fontsize(9pt);
pen labelpen = TimesRoman() + fontsize(10pt);
texpreamble("\usepackage{mathptmx}");

struct Capsule {
	real start;
	real header;
	real body;
	pen headerpen;
	pen bodypen;
	string filename;
	string label;
	string bodylabel;

	real end() {
		return start + header + body;
	}
}

Capsule LFH(real start, real body, string filename="", string label="", string bodylabel="") {
	Capsule c;
	c.start = start;
	c.header = (30 + length(filename))*b;
	c.body = body;
	c.headerpen = lightblue;
	c.bodypen = paleblue;
	c.filename = filename;
	c.label = label;
	c.bodylabel = bodylabel;
	return c;
}

Capsule CDH(real start, string filename="", string label="") {
	Capsule c;
	c.start = start;
	c.header = (46 + length(filename))*b;
	c.body = 0;
	c.headerpen = lightred;
	c.bodypen = palered;
	c.filename = filename;
	c.label = label;
	return c;
}

void draw_capsule(Capsule c) {
	picture pic;
	fill(pic, box((-1, 0-1), (c.header+1, ht+1)), c.headerpen);
	fill(pic, box((c.header, 0-1), (c.header+c.body+1, ht+1)), c.bodypen);
	path boundary =
		(capsuleradius+sp, 0)
		-- (c.header+c.body-capsuleradius-sp, 0){right}
		:: {up}(c.header+c.body-sp, ht/2){up}
		:: {left}(c.header+c.body-capsuleradius-sp, ht)
		-- (capsuleradius+sp, ht){left}
		:: {down}(sp, ht/2){down}
		:: {right}(capsuleradius+sp, 0)
		-- cycle;
	label(pic, baseline(c.filename), ((capsuleradius+c.header)/2, ht*1/4), p=filenamepen);
	label(pic, baseline(c.label), ((capsuleradius+c.header)/2, ht*2/3), p=labelpen);
	label(pic, baseline(c.bodylabel), ((c.header+c.header+c.body-capsuleradius)/2, ht*1/2), p=labelpen);
	clip(pic, boundary);
	add(shift(c.start, 0) * pic);
}

void draw_reference(real start, real end, int tier, bool drawarrow=true) {
	path p =
		(start, 0)
		-- arc((start-tierradius, -((tier+1)*tiersp)+tierradius), tierradius, 360, 270)
		-- arc((end+tierradius, -((tier+1)*tiersp)+tierradius), tierradius, 270, 180)
		-- (end, 0);
	draw(shift(0, -sp) * p, arrow=drawarrow ? Arrow() : None, p=heavygray);
}

void draw_span(real start, real end, int tier, string label, bool draw_arrows=true) {
	picture pic1;
	label(pic1, baseline(label), ((start+end)/2, 0), p=labelpen);
	// get the bounding box of just the text
	frame bb = bbox(pic1);
	real textheight = ypart(max(bb)) - ypart(min(bb));
	transform tr = shift(0, ht+sp+(tier-1)*spansp+textheight/2);
	add(tr * pic1);
	if (draw_arrows) {
		// clip out the middle so as not to draw over the text
		path[] bc = box(min(bb), max(bb)) ^^ box((start, ypart(min(bb))), (end, ypart(max(bb))));
		picture pic2;
		draw(pic2, ((start+sp, 0) -- (end-sp, 0)), bar=Bars, arrow=Arrows(), p=heavygray);
		clip(pic2, bc, fillrule=evenodd);
		add(tr * pic2);
	}
}
