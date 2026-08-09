library(data.table)
library(ggplot2)
library(grid)

column.width <- (7.0 - 0.33) / 2


## max_uncompressed_size.pdf

data <- fread("compressed_size.csv")
data.max <- data[, .(max_uncompressed_size=max(uncompressed_size)), .(engine, compressed_size)]

# Don't show bzip2 on this graph.
data.max <- data.max[engine != "bzip2"]
# Info-ZIP and zlib are exactly coincident over their shared domain. Assert
# that it is so, because the labels down below make that assumption.
(function() {
	shared_domain <- intersect(data.max[engine == "infozip"]$compressed_size, data.max[engine == "infozip"]$compressed_size)
	infozip <- data.max[engine == "infozip" & compressed_size %in% shared_domain]$max_uncompressed_size
	zlib <- data.max[engine == "zlib" & compressed_size %in% shared_domain]$max_uncompressed_size
	if (!all(infozip == zlib)) {
		stop("infozip and zlib not equal")
	}
})()
data.max <- data.max[engine != "infozip"]

xmin <- 21070
xmax <- 21090
ymin <- 21700000
ymax <- 21750000

p <- ggplot(data.max, aes(compressed_size, max_uncompressed_size, color=engine))
p <- p + geom_point()
p <- p + scale_x_continuous(limits=c(xmin, xmax), minor_breaks=NULL)
p <- p + scale_y_continuous(limits=c(ymin, ymax))
p <- p + scale_color_manual(values=c(bulk_deflate="black", zopfli="slateblue", zlib="dodgerblue"))
p <- p + labs(x="size of DEFLATE stream", y="maximum uncompressed size")
p <- p + theme_minimal()
p <- p + theme(text=element_text(size=10, family="Times"), legend.position="none")

# We need to figure out the aspect ratio of just the panel, in order to compute
# the rotation angle for the labels.
# https://stackoverflow.com/questions/16422847/save-plot-with-a-given-aspect-ratio
output.width <- column.width
output.height <- 3
# Workaround to prevent ggplot_build from creating an empty Rplots.pdf file.
# https://github.com/tidyverse/ggplot2/issues/809
# https://github.com/tidyverse/ggplot2/issues/1042
cairo_pdf(filename="/dev/null")
g <- ggplot_gtable(ggplot_build(p))
panel.width <- output.width - convertWidth(sum(g$widths), "in", valueOnly=TRUE)
panel.height <- output.height - convertWidth(sum(g$heights), "in", valueOnly=TRUE)

# The slope of the lines in data space is 1032/1.
angle <- atan2(1032*panel.height/(ymax-ymin), 1*panel.width/(xmax-xmin)) * (180/pi)
p <- p + annotate("text", x=21075, y=data.max[engine == "bulk_deflate" & compressed_size==21075]$max_uncompressed_size, label="bulk_deflate", angle=angle, hjust=0, vjust=-0.6, family="Times")
p <- p + annotate("text", x=21075, y=data.max[engine == "zopfli" & compressed_size==21075]$max_uncompressed_size, label="Zopfli", angle=angle, hjust=0, vjust=-0.6, family="Times")
p <- p + annotate("text", x=21075, y=data.max[engine == "zlib" & compressed_size==21075]$max_uncompressed_size, label="zlib and Info-ZIP", angle=angle, hjust=0, vjust=-0.6, family="Times")

ggsave("max_uncompressed_size.pdf", p, width=output.width, height=output.height, device=cairo_pdf)


## zipped_size.pdf

data <- read.csv("zipped_size.csv")
data <- data.table(data)

byte_breaks <- 1000^(0:6)
byte_breaks_minor <- c(byte_breaks*10, byte_breaks*100)
byte_labels <- c("1 B", "1 kB", "1 MB", "1 GB", "1 TB", "1 PB", "1 EB")

xmin <- min(data$zipped_size, data$unzipped_size)
xmax <- 1000^3
ymin <- min(data$zipped_size, data$unzipped_size)
ymax <- 1000^6

data <- data[(class %in% c(
	# "full_bzip2",
	# "full_bzip2_zip64",
	# "full_deflate",
	# "full_deflate_zip64",
	"none_bzip2",
	"none_bzip2_zip64",
	"none_deflate",
	"none_deflate_zip64",
	"quoted_deflate",
	"quoted_deflate_zip64",
	# "quoted_deflate_extra",
	# "quoted_deflate_zip64_extra",
	"quoted_bzip2_extra",
	"quoted_bzip2_zip64_extra",
	"42_nonrec",
	"42_rec"
))]

palette <- c(
	full_bzip2="pink",
	full_bzip2_zip64="pink",
	full_deflate="pink",
	full_deflate_zip64="pink",
	none_bzip2="coral",
	none_bzip2_zip64="lightcoral",
	none_deflate="darkslateblue",
	none_deflate_zip64="lightslateblue",
	quoted_deflate="midnightblue",
	quoted_deflate_zip64="slateblue",
	quoted_deflate_extra="pink",
	quoted_deflate_zip64_extra="pink",
	quoted_bzip2_extra="salmon",
	quoted_bzip2_zip64_extra="lightsalmon",
	"42_nonrec"="red",
	"42_rec"="red"
)

p <- ggplot(data)
# p <- p + geom_hline(yintercept=281470681677825, size=0.5, linetype=2, color="gray")
p <- p + geom_abline(slope=1, intercept=0, size=0.2, linetype=3)
# p <- p + geom_point(data=data[class %in% c("42_nonrec", "42_rec")], aes(zipped_size, unzipped_size, color=class))
p <- p + geom_line(size=0.4, aes(zipped_size, unzipped_size, color=class), alpha=0.8)
p <- p + scale_color_manual(values=palette)
p <- p + scale_x_log10(breaks=byte_breaks, labels=byte_labels, minor_breaks=byte_breaks_minor)
p <- p + scale_y_log10(breaks=byte_breaks, labels=byte_labels, minor_breaks=byte_breaks_minor)
p <- p + coord_fixed(xlim=c(xmin, xmax), ylim=c(ymin, ymax))
p <- p + labs(x="zipped size", y="unzipped size")
p <- p + theme_minimal()
p <- p + theme(text=element_text(size=10, family="Times"), legend.position="none")

# Like approx, but linearly extrapolates beyond the endpoints
interp <- function(at, x, y) {
	i <- findInterval(at, x)
	if (i == 0) {
		slope <- (y[[2]] - y[[1]]) / (x[[2]] - x[[1]])
		ref <- 1
	} else if (i == length(x)) {
		slope <- (y[[i]] - y[[i-1]]) / (x[[i]] - x[[i-1]])
		ref <- i
	} else {
		slope <- (y[[i+1]] - y[[i]]) / (x[[i+1]] - x[[i]])
		ref <- i
	}
	y[[ref]] + slope * (at - x[[ref]])
}

angle_label_at_sub <- function(at, x, y, angle, label, hjust, vjust) {
	annotate("text", x=at, y=interp(at, x, y), angle=angle, label=label, hjust=hjust, vjust=vjust, size=3, family="Times")
}

angle_label_at <- function(at, df, angle, label, hjust, vjust) {
	df <- df[order(df$zipped_size)]
	angle_label_at_sub(at, df$zipped_size, df$unzipped_size, angle, label, hjust, vjust)
}

p <- p + angle_label_at(10^7.95, data[class=="none_deflate"], label="no-overlap DEFLATE", angle=45, 1, -0.3)
p <- p + angle_label_at(10^8.1, data[class=="none_deflate_zip64"], label="(Zip64)", angle=45, 0, -0.3)
p <- p + angle_label_at(10^8.2, data[class=="none_bzip2"], label="no-overlap bzip2", angle=45, 1, +1.4)
p <- p + angle_label_at(10^8.35, data[class=="none_bzip2_zip64"], label="(Zip64)", angle=45, 0, +1.4)
p <- p + angle_label_at(10^6.95, data[class=="quoted_deflate"], label="quoted DEFLATE", angle=atan2(2, 1)*180/pi, 1, -0.3)
p <- p + angle_label_at(10^7.1, data[class=="quoted_deflate_zip64"], label="(Zip64)", angle=atan2(2, 1)*180/pi, 0, -0.3)
p <- p + angle_label_at(10^3.5, data[class=="quoted_bzip2_extra"], label="extra-field-quoted bzip2", angle=atan2(2, 1)*180/pi, 0.6, -0.3)
p <- p + angle_label_at(10^4.25, data[class=="quoted_bzip2_zip64_extra"], label="(Zip64)", angle=atan2(2, 1)*180/pi, 0, -0.3)

points <- fread("
label,class,x,y,nudge_h,nudge_v
zbsm.zip,quoted_deflate,42374,5461307620,0.15,0.0
zblg.zip,quoted_deflate,9893525,281395456244934,0.15,0.0
zbxl.zip,quoted_deflate_zip64,45876952,4507981427706459.0,0.15,0.0
42.zip (non-recursive),42_nonrec,42374,558432,0.0,-0.25
42.zip (recursive),42_rec,42374,4507981343026016,0.0,0.25
")
# zbbz2.zip,quoted_bzip2_extra,155846,7721949598695,-0.15,0.0
# p <- p + geom_segment(data=points, aes(x=x, y=y, xend=xend, yend=yend), size=0.2, alpha=0.5, position=position_nudge(points$nudge_h, points$nudge_v), arrow=arrow(length=unit(0.2, "cm")))
p <- p + geom_point(data=points, aes(x=x, y=y, color=class), size=1)
p <- p + geom_text(data=points, aes(x=x, y=y, label=label), color="#888888", position=position_nudge(points$nudge_h, points$nudge_v), size=2.75, hjust=0.5*(1.0-sign(points$nudge_h)), vjust=0.5, family="Times")

ggsave("zipped_size.pdf", p, width=column.width, height=6.5, device=cairo_pdf)
