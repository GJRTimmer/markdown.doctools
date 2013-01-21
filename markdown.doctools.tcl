#
# MANAGEMENT COMMANDS
#

proc fmt_numpasses {} {
	return 2
}

proc fmt_listvariables {} {
	return {}
}

proc fmt_varset {varname value} {
	# no module configuration variables supported
	# could provide options to toggle behavior between GitHub flavor and vanilla
	error "unknown variable $varname"
}

proc fmt_initialize {} {
	global docinfo
	set docinfo [dict create category {} copyright {} keywords {} moddesc {} require {} see_also {} titledesc {} synopsis {}]
}

proc fmt_setup {pass} {
	switch $pass 1 mddt_setup_1 2 mddt_setup_2
}

proc fmt_postprocess {text} {
	# for the purpose of condensing excess paragraph breaks, it's important
	# to look *only* for repeated newlines such as we produce to make p breaks,
	# and not any "blank" lines with other whitespace (eg indentation), which
	# may be significant in the context of that content (eg an example) 
	return [regsub -all "\n{2,}" $text "\n\n"]
	#return $text
}

proc fmt_shutdown {} {
}

#
# PASS SETUP
#

proc mddt_setup_1 {} {
	
	#
	# Document information commands active
	#
	
	# fmt_call and fmt_usage should also be scanned in
	# pass 1 to accumulate synopsis listings.
	# Note that their arguments may be formatted with other markup commands,
	# though, so we do need to invoke those somehow.
	
	# note: "If more than one pass is required to perform the formatting only
	# the output of the last pass is relevant. The output of all the previous,
	# preparatory passes is ignored." Soooo, text markup commands could be
	# active permanently. On pass one, they'd only meaningfully be used to
	# format text that get scanned eg for synopsis, such as call or usage args.
	# With this approach, only the docinfo commands (and others that scan on
	# pass one) may need to be toggled.
	
	# built-in text formatter doesn't return text, but rather stores it all
	# in a cmds "display list" global, which it finally processes & returns
	# from fmt_postprocess.
	
	# name of document category (single string)
	proc fmt_category {text} {
		global docinfo
		dict set docinfo category $text
	}

	# document copyright (list of strings)
	proc fmt_copyright {text} {
		global docinfo
		dict lappend docinfo copyright $text
	}
	
	# document keywords (list of strings)
	proc fmt_keywords {args} {
		global docinfo
		dict lappend docinfo keywords {*}$args
	}

	# document module description (single string)
	proc fmt_moddesc {text} {
		global docinfo
		dict set docinfo moddesc $text
		if {[dict get $docinfo titledesc] eq {}} {
			dict set docinfo titledesc $text
		}
	}

	# package requirements of document module (list of {package version} lists)
	proc fmt_require {package {version {}}} {
		global docinfo
		dict lappend docinfo require [list $package $version]
	}

	# cross-references to other documents (list of strings)
	proc fmt_see_also {args} {
		global docinfo
		dict lappend docinfo see_also {*}$args
	}

	# document description (single string; defaults to moddesc)
	proc fmt_titledesc {text} {
		global docinfo
		dict set docinfo titledesc $text
	}
	
	#
	# Text structure and markup commands ignored during first pass.
	#
	
	proc fmt_plain_text {text} {}
	
	# text structure
	proc fmt_arg_def {type name {mode {}}} {}
	proc fmt_call {cmd args} {} ; # scan for synopsis
	proc fmt_cmd_def {command} {}
	proc fmt_def {text} {}
	proc fmt_description {id} {}
	proc fmt_enum {} {}
	proc fmt_example {text} {}
	proc fmt_example_begin {} {}
	proc fmt_example_end {} {}
	proc fmt_item {} {}
	proc fmt_list_begin {type {hint {}}} {}
	proc fmt_list_end {} {}
	proc fmt_manpage_begin {command section version} {}
	proc fmt_manpage_end {} {}
	proc fmt_opt_def {name {arg {}}} {}
	proc fmt_para {} {}
	proc fmt_section {name {id {}}} {} ; # scan for toc
	proc fmt_subsection {name {id {}}} {} ; # scan for toc
	proc fmt_tkoption_def {name dbname dbclass} {}	
	
	# text markup
	proc fmt_arg {text} {}
	proc fmt_class {text} {}
	proc fmt_cmd {text} {}
	proc fmt_const {text} {}
	proc fmt_emph {text} {}
	proc fmt_file {text} {}
	proc fmt_fun {text} {}
	proc fmt_image {id {label {}}} {}
	proc fmt_method {text} {}
	proc fmt_namespace {text} {}
	proc fmt_opt {text} {}
	proc fmt_option {text} {}
	proc fmt_package {text} {}
	proc fmt_sectref {id {label {}}} {}
	proc fmt_sectref-external {label} {}
	proc fmt_syscmd {text} {}
	proc fmt_term {text} {}
	proc fmt_type {text} {}
	proc fmt_uri {uri {label {}}} {}
	proc fmt_usage {args} {} ; # scan for synopsis
	proc fmt_var {text} {}
	proc fmt_widget {text} {}
	
	# deprecated
	proc fmt_bullet {} {}
	proc fmt_lst_item {text} {}
	proc fmt_nl {} {}
	proc fmt_strong {text} {}
}

proc mddt_setup_2 {} {

	#
	# Document information commands ignored during second pass.
	#
	
	proc fmt_category {text} {}
	proc fmt_copyright {text} {}
	proc fmt_keywords {args} {}
	proc fmt_moddesc {text} {}
	proc fmt_require {package {version {}}} {}
	proc fmt_see_also {args} {}
	proc fmt_titledesc {text} {}
	
	# strip newlines
	proc mddt_collapse_newlines {text} {
		return [regsub -all -- "\n" $text {}]
	}
	
	# plain text (context dependent)
	proc fmt_plain_text {text} {
		switch -- [ex_cname] {
			example {
				# Append example content to the example context output buffer;
				# output nothing now. Unifies [example] command and begin/end.
				ex_cappend $text
				set text {}
			}
			dl {
				# skip blank lines
				if {[regexp -- {^\s*$} $text]} {
					return {}
				}
				
				set text [regsub -- "^\n*" $text {}]
				set text [regsub -- "\n+$" $text {}]
				set text [mddt_collapse_newlines $text] 
				set text [regsub -all -line -- "^" $text "> "]
			}
			default {
				set text [mddt_collapse_newlines $text]
			}
		}
		return $text
	}

	#
	# Text structure commands
	#
	
	proc fmt_arg_def {type name {mode {}}} {
		# arguments dl list element
		return "\n\n${type} ${name}\n\n"
	}
	
	proc fmt_call {cmd args} {
		# general dl list element
		set arguments {}
		foreach arg $args {
			append arguments [format { %s} $arg]
		}
		return "\n\n${cmd}${arguments}\n\n"
	}
	
	proc fmt_cmd_def {command} {
		# commands dl list element
		return "\n\n${command}\n\n"
	}
	
	proc fmt_def {text} {
		# general dl list element
		return "\n\n${text}\n\n"
	}
	
	proc fmt_description {id} {
		# "Implicitly starts a section named "DESCRIPTION""
		return [fmt_section DESCRIPTION]
	}
	
	proc fmt_enum {} {
		# enumerated ol list element
		set counter [ex_cget enum]
		ex_cset enum [incr counter]
		return "\n${counter}. "
	}
	
	proc fmt_example_begin {} {
		ex_cpush example
		return "\n\n"
	}
	
	proc fmt_example_end {} {
		set text [ex_cpop example]
		
		# trim leading/trailing newlines and indent content
		set text [regsub -- "^\n*" $text {}]
		set text [regsub -- "\n+$" $text {}]
		set text [regsub -all -line -- "^" $text "\t"]
		
		return "${text}\n\n"
	}
	
	proc fmt_item {} {
		# itemized ul list element
		return "\n- "
	}
	
	# hint is undocumented
	proc fmt_list_begin {type {hint {}}} {

		switch $type {
			arg -
			args -
			arguments {
				# arg_def (dl)
				ex_cpush dl
			}
			cmd -
			cmds -
			commands {
				# cmd_def (dl)
				ex_cpush dl
			}
			definitions {
				# def or call (dl)
				ex_cpush dl
			}
			enum -
			enumerated {
				# enum (ol)
				ex_cpush ol
				ex_cset enum 0
			}
			bullet -
			item -
			itemized {
				# item (ul)
				ex_cpush ul
			}
			opt -
			opts -
			options {
				# opt_def (dl)
				ex_cpush dl
			}
			tkoption -
			tkoptions {
				# tkoption_def (dl)
				ex_cpush dl
			}
			default {
				error "unknown list type $type"
			}
		}
		return
	}
	
	proc fmt_list_end {} {
		# close current list
		set text [ex_cpop [ex_cname]]
		
		# one generic "list" context may be sufficient (and certainly simpler)
		# than separate ul, ol, and dl list categories.
		set parentContext [ex_cname]
		if {$parentContext eq "ul" || $parentContext eq "ol" || $parentContext eq "dl"} {
			set text [regsub -- "^\n*" $text {}]
			set text [regsub -all -line -- "^" $text "\t"]
			set text "\n${text}"
		} else {
			set text "${text}\n\n"
		}
		
		return $text
	}
	
	proc fmt_manpage_begin {command section version} {
		global docinfo
		# output header
		return [fmt_section "$command"]
	}
	
	proc fmt_manpage_end {} {
		# output footer
	}
	
	proc fmt_opt_def {name {arg {}}} {
		# options dl list element
		set argument {}
		if {$arg ne {}} {
			set argument [format { %s} $arg]
		}
		return "\n\n${name}${argument}\n\n"
	}
	
	proc fmt_para {} {
		# paragraph - empty line
		# the reason I'm reluctant to add context rules here as well as in
		# plain_text is that it seems there are many places where they must
		# then be enforced - anywhere that newlines may be added to seperate
		# blocks. Perhaps the solution is a standalone proc that all of these
		# cases can call to provide "context-sensitive block seperators"
		# (eg, newlines with proper prefixes/indentation)
		if {[ex_cis dl]} {
			return "\n> \n"
		}
		return "\n\n"
	}
	
	proc fmt_section {name {id {}}} {
		# h1
		return "\n\n# $name\n\n"
	}
	
	proc fmt_subsection {name {id {}}} {
		# h2
		return "\n\n## $name\n\n"
	}
	
	proc fmt_tkoption_def {name dbname dbclass} {
		# tkoptions dl list element
		return "\n\n${name} ${dbname} ${dbclass}\n\n"
	}
	
	#
	# Text markup commands
	#
	
	# name of a command argument
	proc fmt_arg {text} {
		# em
		return "*$text*"
	}

	# name of a class
	proc fmt_class {text} {
		# code
		return "`$text`"
	}

	# name of a Tcl command
	proc fmt_cmd {text} {
		# code
		return "`$text`"
	}

	# value of a constant
	proc fmt_const {text} {
		# code
		return "`$text`"
	}

	# generic emphasis
	proc fmt_emph {text} {
		# strong
		return "**$text**"
	}

	# name of a file or directory (a path)
	proc fmt_file {text} {
		# quoted code
		return "\"`$text`\""
	}

	# name of a function
	proc fmt_fun {text} {
		# code
		return "`$text`"
	}

	# image id (URI) and possibly label
	proc fmt_image {id {label {}}} {
		if {$label eq {}} {
			set label $id
		}
		# embedded img
		return "!\[$label\]($id)"
	}

	# name of an object method
	proc fmt_method {text} {
		# code
		return "`$text`"
	}

	# name of a namespace
	proc fmt_namespace {text} {
		# code
		return "`$text`"
	}

	# optional, as command arguments
	proc fmt_opt {text} {
		# quoted with ?
		return "?$text?"
	}

	# name of an option (ie, a command switch)
	proc fmt_option {text} {
		# code
		return "`$text`"
	}

	# name of package
	proc fmt_package {text} {
		# code
		return "`$text`"
	}

	# reference to section id, possibly with label
	# another stupid doctools quirk: fmt_sectref gets args in reverse order of [sectref]
	proc fmt_sectref {id {label {}}} {
		if {$label eq {}} {
			set label $id
		}
		# strong link
		return "**$label**"
	}

	# reference to external section with label
	proc fmt_sectref-external {label} {
		# strong
		return "**$label**"
	}

	# name of an external command
	proc fmt_syscmd {text} {
		# code
		return "`$text`"
	}

	# general terminology
	proc fmt_term {text} {
		# em
		return "*$text*"
	}

	# name of a data type
	proc fmt_type {text} {
		# code
		return "`$text`"
	}

	# URI and possibly its label
	proc fmt_uri {uri {label {}}} {
		if {$label eq {}} {
			set label $uri
		}
		# link
		return "\[$label\]($uri)"
	}

	# syntax of a command (first arg) with arguments (remainder of args)
	# like call, but silent; used only to populate synopsis
	proc fmt_usage {args} {}

	# name of a variable
	proc fmt_var {text} {
		# code
		return "`$text`"
	}

	# name of a widget
	proc fmt_widget {text} {
		# code
		return "`$text`"
	}
	
	# deprecated
	proc fmt_bullet {} {fmt_item}
	proc fmt_lst_item {text} {fmt_def $text}
	proc fmt_nl {} {fmt_para}
	proc fmt_strong {text} {fmt_emph $text}
}
