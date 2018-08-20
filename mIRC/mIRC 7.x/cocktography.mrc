;Secret Dechoder Ring v??? by Vin, Tefad
;
; This script will automatically dechode and display messages
; encockted via cocktography. To transmit an enchoded message
; use:
;
; /enchode Text to send
; Use the option --strokes N, or -sN to attempt N encoding stroke iterations
; Begin message with "/me " to send an action
;
; To manually dechode a message, use:
;
; /dechode enchoded message
;  
; This script relies on a hash table to function.
; The contents of this table can be gotten from:
; https://raw.githubusercontent.com/fidsah/cocktography/master/mIRC/mIRC%207.x/cock/rodsetta_stone.txt
; Save the contents as "rodsetta_stone.txt" in the same location as the script
; or modify the "hload" command in the following script block
 
on 1:start: {
; format variables have the following moustaches available:
; {{nick}} the nick for the message
; {{enchoded}} the dongified message
; {{dechoded}} the payload in plaintext
; {{count}} the number of MIME encoding iterations used
; {{stroke}} the stroke format string as specified
; NOTE: The following block of sets are initial values.
; To change their values, you must use the /set command or
; use the mIRC Scripts Editor - Variables tab

; The next variable dictatates the final entry which follows. Use an integer.
  set -ign %cocktography.stroke_max_format 3
  set -ign %cocktography.stroke_0_format 030🐓
  set -ign %cocktography.stroke_1_format 041🍆
  set -ign %cocktography.stroke_2_format 04🍆
  set -ign %cocktography.stroke_3_format 04{{count}}🍆
  set -ign %cocktography.text_format   {{stroke}}<{{nick}}> {{dechoded}}
  set -ign %cocktography.action_format * {{stroke}}{{nick}} {{dechoded}}
  set -ign %cocktography.strokes_default 2
  set -ign %cocktography.payload_max 150
  set -ign %cocktography.cockblock_max 340
  set -ign %cocktography.stroketext_max 280  
  hfree -w cocktography.*
  hload -m cocktography.dec $scriptdir $+ rodsetta_stone.txt
  hmake cocktography.enc
  set -egn %cocktography.hkey $!iif($event,$+($server,/,$target,/,$fulladdress,/,$event),command)
  set -egn %cocktography.start $hget(cocktography.dec, start)
  set -egn %cocktography.stop  $hget(cocktography.dec, stop)
  set -egn %cocktography.mark  $hget(cocktography.dec, mark)
  set -egn %cocktography.cont  $hget(cocktography.dec, cont)
  set -egn %cocktography.term  $chr(15)
  set -egn %cocktography.singleton_mask    %cocktography.start * %cocktography.stop
  set -egn %cocktography.initial_mask      %cocktography.start * %cocktography.cont
  set -egn %cocktography.intermediate_mask %cocktography.mark  * %cocktography.cont
  set -egn %cocktography.final_mask         %cocktography.mark  * %cocktography.stop
  var -n %i $hget(cocktography.dec, 0).item
  while (%i) {
    var %value $hget(cocktography.dec, %i).item
    var %key $hget(cocktography.dec, %value)
    if ($len(%key) == 1) { hadd cocktography.enc $asc(%key) %value }
    else { hdel cocktography.dec %value }
    dec %i
  }
}

; Stroke buffer utilities for use in events
alias strokebuffer { returnex $hget(cocktography.buf, $evalnext(%cocktography.hkey)) }
alias setstrokebuffer {
  hadd -mu10 cocktography.buf $evalnext(%cocktography.hkey) $$1-
  halt
}
alias appendstrokebuffer {
  var -n %key $evalnext(%cocktography.hkey)
  hadd -mu10 cocktography.buf %key $hget(cocktography.buf, %key) $+ $$1-
  halt
}

; Stroke count utilities
alias setstrokes { hadd -mu10 cocktography.strokes $evalnext(%cocktography.hkey) $parms }
alias strokes { returnex $hget(cocktography.strokes, $evalnext(%cocktography.hkey)) }

; Command which mimics plaintext output
; parm1: event
; parm2: stroketext
alias dechodeecho {
  var -n %key $evalnext(%cocktography.hkey)
  var -n %enchoded $$2-
  var -n %dechoded $destroke(%enchoded)
  var -n %nick $iif($event, $nick, $me), %strokes $strokes
  var -n %index $iif(%strokes > %cocktography.stroke_max_format, %cocktography.stroke_max_format, %strokes)
  var -n %stroke $+(%, cocktography.stroke_, %index, _format)
  var -n %format $+(%, cocktography., $$1, _format)
  %stroke = $replacexcs($evalnext(%stroke), {{count}}, %strokes)
  %format = $replacexcs($evalnext(%format), {{stroke}}, %stroke, {{nick}}, %nick, {{enchoded}}, %enchoded, {{dechoded}}, %dechoded)
  echo $color($$1) -lbft $iif($event, $target, $active) %format
  halt
}

; Identifier which recursively MIME decodes until sentinel or bust
; parm1: encoded text
alias destroke {
  var -n %strokes 0, %out $$1
  while ($destrokable(%out)) {
    %out = $decode(%out, m)
    inc %strokes
  }
  if ($left(%out, 1) === %cocktography.term) { %out = $right(%out, -1) }
  setstrokes %strokes
  returnex %out
}

; Utility identifier used in $destroke to improve readability
; parm1: encoded text
alias destrokable {
; Is the first character the terminator sentinel?
  if ($right($1, 1) === %cocktography.term) { return $false }
; Is it an invalid MIME base64 length? (indivisible by 4)
  elseif (4 \\ $len($1)) { return $false }
; Are there any non MIME base64 characters?  
  elseif ($regex($1, /[^+/=0-9A-Za-z]/)) { return $false }
; Are there no characters?  
  elseif (!$len($1)) { return $false }
  else { return $true }
}

; Identifier which derives stroketext from dongs
; parm1: dong text
alias decyphallus {
  tokenize 32 $$1
  var %i 1, %out, %char
  while (%i <= $0) {
    %out = $+($left(%out, -1), $hget(cocktography.dec, $evalnext($ $+ %i)), .)
    inc %i
  }
  returnex $left(%out, -1)
 }
 
; Intercept singleton cockblock/cockchain
on ^1:text:%cocktography.singleton_mask:#:   dechodeecho $event $decyphallus($parms)
on ^1:action:%cocktography.singleton_mask:#: dechodeecho $event $decyphallus($parms)
 
; Intercept first cockblock in a cockchain
on ^1:text:%cocktography.initial_mask:#:   setstrokebuffer $decyphallus($parms)
on ^1:action:%cocktography.initial_mask:#: setstrokebuffer $decyphallus($parms)
 
; Intercept intermediate cockblock in a cockchain
on ^1:text:%cocktography.intermediate_mask:#:   appendstrokebuffer $decyphallus($parms)
on ^1:action:%cocktography.intermediate_mask:#: appendstrokebuffer $decyphallus($parms)
 
; Intercept final cockblock in a cockchain
on ^1:text:%cocktography.final_mask:#:   dechodeecho $event $strokebuffer $+ $decyphallus($parms)
on ^1:action:%cocktography.final_mask:#: dechodeecho $event $strokebuffer $+ $decyphallus($parms)

; Command to enchode text. This includes stroking text, cocking it up,
;   and chopping it into cockblocks and streaming out the cockchain.
; opts:
; strokes (optional), shortname s: apply this amount of encoding strokes
; NOTE: input starting with "/me " will be converted to an action
; payload is restricted to 150 characters
; strokes are limited to producing roughly 370 characters of stroketext
alias enchode {
  var %strokes %cocktography.strokes_default, %input $parms
  if ($regex(%input, /^(-s ?|--strokes?[ =])([0-9]+)( +)/) && $regml(0) == 3) {
    %strokes = $regml(2)
    var -n %len $calc($len($regml(1)) + $len(%strokes) + $len($regml(3)) + 1)
    %input = $mid(%input, %len)
  }
  if ($len(%input) > %cocktography.payload_max) {
    %input = $left(%input, %cocktography.payload_max)
    echo -at 4Warning: Truncating enchoded text truncated to prevent excess flood.
  }
  if ($regex(%input, /^/me /)) {
    var -n %action $true
    %input = $right(%input, -4)
  }
  tokenize 32 $cyphallus($stroke(%input, %strokes))
  var -n %i 1, %out %cocktography.start, %cumout
  while (%i <= $0) {
    %out = %out $evalnext($ $+ %i)
    if ($len(%out) > %cocktography.cockblock_max) {
      %out = %out %cocktography.cont
      %cumout = %cumout %out
      if (%action) { .describe $active %out }
      else { .msg $active %out }
      %out = %cocktography.mark
    }
    inc %i
  }
  %out = %out %cocktography.stop
  %cumout = %cumout %out
  if (%action) { .describe $active %out }
  else { .msg $active %out }
  dechodeecho $iif(%action, action, text) $decyphallus(%cumout)
}

; Command which turns a cockchain to plaintext
alias dechode {
  echo -at 4Dechoded $strokes $+ -stroke Message: [ $destroke($decyphallus($parms)) ]
}
 
; Identifier which attempts to recusively MIME encode the specified amount
; parm1: plaintext to encode
; parm2: number of times to attempt to recursely
alias stroke {
  var %out %cocktography.term $+ $$1, %i $$2
  while (%i > 0 && $len(%out) < %cocktography.stroketext_max) {
    %out = $encode(%out, m)
    dec %i
  }
  if (%i) {
    echo -at 4Warning: Skipping %i of $$2 strokes to prevent excess flood.
  }
  return %out
}
 
; Identifier which cockifies input
; parm1: text to cock up
alias cyphallus {
  var %pos 1, %len $len($$1), %out
  while (%pos <= %len) {
    if ($hget(cocktography.enc, $asc($mid($1, %pos, 1)))) { %out = %out $v1 }
    inc %pos
  }
  return %out
}
