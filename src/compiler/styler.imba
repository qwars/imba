
var conv = require('../../vendor/colors')
import {fonts,colors,variants,breakpoints} from './theme.imba'

const extensions = {}

# add some rounded size presents

###
bg: background
ph: placeholder


# special flow shorthands

# horizontal align r/h/x

[l]eft
[c]enter
[r]ight
[s]stretch
[b]baseline

# vertical align c/v/y

[t]op
[m]iddle
[b]ottom
[s]tretch

# justify content
[s]tart
[c]enter
[e]nd
[j]ustify - space-between
[d]istribute - space-evenly
[a]round - space-around



# either
[j]ustify - space-between
[d]istribute - space-evenly
[b]etween


# shorthand follows format
direction-xaxis-yaxis

vtc (vertical top center)

# Either follow format direction-x-y or direction-along-across
# direction-along-across

vss - vertical from start - stretching children
vcc - vertical from center - centered children
vsc - vertical from start - centered 
vsl - vertical from start - children aligned to the left

vst
vcm
hjc - horizontal justified 

vmc - vertical middle ccenter
vml - vertical middle left

hcm - horizontal center middle
hlm - horizontal left middle

###

# should not happen at root - but create a theme instance

var palette = {
	current: {string: "currentColor"}
	black: {string: "hsla(0,0,0,var(--alpha,1))"}
	white: {string: "hsla(0,100%,100%,var(--alpha,1))"}
}

for own name,variations of colors
	let subcolors = {}
	
	for own subname,hex of variations
		let path = name + '-' + subname
		let color = subcolors[subname] = {}
		palette[path] = color

		let rgb = conv.hex.rgb(hex)
		let [h,s,l] = conv.rgb.hsl(rgb)
		color.hex = conv.hex.rgb(hex)
		color.h = h
		color.s = s
		color.l = l
		
		let hslstr = "{h.toFixed(2)},{s.toFixed(2)}%,{l.toFixed(2)}%"
		color.string = "hsla({hslstr},var(--alpha,1))"


# var colorRegex = RegExp.new('^(?:(\\w+)\-)?(' + Object.keys(palette).join('|') + ')\\b')
var colorRegex = RegExp.new('\\b(' + Object.keys(palette).join('|') + ')\\b')

class Selectors
	static def parse context, states
		let parser = self.new
		parser.$parse(context,states)
		
	def $parse context, states
		let rule = '&'
		o = {context: context, media: []}
		for [state,...params] in states
			let res

			unless self[state]
				if let media = breakpoints[state]
					o.media.push(media)
					continue
					
				elif state.indexOf('&') >= 0
					res = state
				else
					let [prefix,...flags] = state.split('-')
					if self[prefix] and flags.length
						params.unshift(".{flags.join('.')}")
						state = prefix
						console.log 'added params',params
			
			if self[state]
				res = self[state](...params)

			if typeof res == 'string'
				rule = rule.replace('&',res)


		let sel = rule.replace(/\&/g,context)
		
		# possibly expand selectors?

		o.selectors = [sel]
		if o.media.length
			sel = '@media ' + o.media.join(' and ') + '{ ' + sel
		return sel

	def any
		'&'
		
	def pseudo type,sel
		sel ? "{sel}{type} &" : "&{type}"

	def hover sel
		pseudo(':hover',sel)
	
	def focus sel
		pseudo(':focus',sel)

	def active sel
		pseudo(':active',sel)
		
	def visited sel
		pseudo(':visited',sel)
	
	def disabled sel
		pseudo(':disabled',sel)
		
	def focus-within sel
		pseudo(':focus-within',sel)
		
	def odd sel
		pseudo(':nth-child(odd)',sel)		
		
	def even sel
		pseudo(':nth-child(even)',sel)
		
	def first sel
		pseudo(':first-child',sel)
		
	def last sel
		pseudo(':last-child',sel)
		
	def empty sel
		pseudo(':empty',sel)
		
	def hocus
		'&:matches(:focus,:hover)'
	
	def up sel
		sel.indexOf('&') >= 0 ? sel : "{sel} &"
	
	def sel sel
		sel.indexOf('&') >= 0 ? sel : "& {sel}"
	
	# selector matching the custom component we are inside
	def scope sel
		sel.indexOf('&') >= 0 ? sel : "{sel} &"

	# :light
	# :dark
	# :ios
	# :android
	# :mac
	# :windows
	# :linux
	# :print

class Rules
	
	static def parse mods
		let parser = self.new
		parser.$parse(mods)
		
	def constructor
		self
	
	def $merge object, result
		if result isa Array
			for item in result
				$merge(object,item)
		else
			for own k,v of result
				if k.indexOf('&') >= 0
					object[k] = Object.assign({},object[k] or {},v)
				else
					object[k] = v

			# Object.assign(object,result)
		return object
				
		
	# pseudostates
	def $parse mods
		let values = {}
		
		for [mod,...params] in mods
			let res = null
			let scopes = mod.split(':')
			let key = scopes.pop()
			let name = key.replace(/\-/g,'_')
			
			
			if self[name]
				res = self[name](...params)
			
			elif let colormatch = key.match(colorRegex)
				let color = palette[colormatch[1]]	
				let name = key.replace(colorRegex,'COLOR').replace(/\-/g,'_')
			
				if self[name]
					params.unshift(color)
					res = self[name](...params)
			else
				let parts = key.split('-')
				let dropped = []
				while parts.length > 1
					let drop = parts.pop!
					let name = parts.join('_')
					drop = parseFloat(drop) if drop.match(/^-?(\d+)$/)
					params.unshift(drop)
					if self[name]
						res = self[name](...params)
			if res
				if scopes.length
					let obj = {}
					let jsonkey = JSON.stringify(scopes.map(do [$1]))
					obj[jsonkey] = res
					res = obj

				$merge(values,res)

		return values
		
	# converting argument to css values
	def $length value, fallback, type
		if value == undefined
			return $length(fallback,null,type)
		if typeof value == 'number'
			return value * 0.25 + 'rem'
		elif typeof value == 'string'
			return value
			
	def $alpha value
		if typeof value == 'number'
			# is already an integer
			if Math.round(value) == value
				return "{value}%"
		return value
	
	def $value value, config
		if value == undefined
			value = config.default
		
		if config.hasOwnProperty(value)
			value = config[value]
			
		if typeof value == 'number' and config.step
			let [step,num,unit] = config.step.match(/^(\-?[\d\.]+)(\w+|%)?$/)
			return value * parseFloat(num) + unit

		return value
	
	def $radius value
		if value == undefined
			value = variants.radius.default

		if variants.radius.hasOwnProperty(value)
			value = variants.radius[value]
		
		if typeof value == 'number'
			let [step,num,unit] = (variants.radius.step or '0.125rem').match(/^(\-?[\d\.]+)(\w+)?$/)
			return value * parseFloat(num) + unit
			# return (value * 0.125) + 'rem'
			
		return value
			
	# LAYOUT
	
	# Container
	
	def container
		# tricky to implement 
		null
	
	
	# Box Sizing
	
	def box_border do {'box-sizing': 'border-box'}
	def box_content do {'box-sizing': 'content-box'}
	
	# Display
	
	def display v
		{display: v}
		
	def hidden do display('none')
	def block do display('block')
	def flow_root do display('flow-root')
	def inline_block do display('inline-block')
	def inline do display('inline')
	def grid do display('grid')
	def inline_grid do display('inline-grid')
	def table do display('table')
	def table_caption do display('table-caption')
	def table_cell do display('table-cell')
	def table_column do display('table-column')
	def table_column_group do display('table-column-group')
	def table_footer_group do display('table-footer-group')
	def table_header_group do display('table-header-group')
	def table_row_group do display('table-row-group')
	def table_row do display('table-row')
		
	def flex
		display('flex')
		
	def inline_flex
		display('inline-flex')
	
	# Float
	def float_right do {float: 'right'}
	def float_left do {float: 'left'}
	def float_none do {float: 'none'}
	def clearfix do
		{'&::after': {content: "", display: 'table', clear: 'both'}}
	
	# Clear
	def clear_right do {clear: 'right'}
	def clear_left do {clear: 'left'}
	def clear_both do {clear: 'both'}
	def clear_none do {clear: 'none'}
	
	# Object Fit
	def object_contain do {'object-fit': 'contain'}
	def object_cover do {'object-fit': 'cover'}
	def object_fill do {'object-fit': 'fill'}
	def object_none do {'object-fit': 'none'}
	def object_scale_down do {'object-fit': 'scale-down'}
	
	# Object Position
	
	# Overflow
	def overflow_hidden do {overflow: 'hidden'}
	
	# Position
	def static do {position: 'static'}
	def fixed do {position: 'fixed'}
	def abs do {position: 'absolute'}
	def rel do {position: 'relative'}
	def sticky do {position: 'sticky'}
		
	
	# Top / Right / Bottom / Left
	# add longer aliases like left,right,bottom,top?
	def t(v0,v1) do {'top':    $length(v0,v1)}
	def l(v0,v1) do {'left':   $length(v0,v1)}
	def r(v0,v1) do {'right':  $length(v0,v1)}
	def b(v0,v1) do {'bottom': $length(v0,v1)}
	def tl(t,l=t) do  {'top': $length(t),'left': $length(l)}
	def tr(t,r=t) do  {'top': $length(t),'right': $length(r)}
	def bl(b,l=b) do  {'bottom': $length(b),'left': $length(l)}
	def br(b,r=b) do  {'bottom': $length(b),'right': $length(r)}

	def inset(t,r=t,b=t,l=r)
		{
			'top': $length(t),
			'right': $length(r),
			'bottom': $length(b),
			'left': $length(l)
		}
	
	
	# Visibility
	def visible do {visibility: 'visible'}
	def invisible do {visibility: 'hidden'}
	
	# Z-index
	def z(v) do {'z-index': v}
		
	# FLEXBOX
	
	# Flex Direction
	
	def flex_row
		{'flex-direction': 'row'}
	
	def flex_row_reverse
		{'flex-direction': 'row-reverse'}
	
	def flex_col
		{'flex-direction': 'column'}
	
	def flex_col_reverse
		{'flex-direction': 'column-reverse'}
		
	def ltr
		{'flex-direction': 'row'}
	
	def rtl
		{'flex-direction': 'row-reverse'}
	
	def ttb
		{'flex-direction': 'column'}
	
	def btt
		{'flex-direction': 'column-reverse'}

	# add aliases ltr, ttb, btt, rtl?
	
	# Flex Wrap
	def flex_no_wrap do {'flex-wrap': 'no-wrap'}
	def flex_wrap do {'flex-wrap': 'wrap'}
	def flex_wrap_reverse do {'flex-wrap': 'wrap-reverse'}
	
	def center do
		{
			'align-items': 'center',
			'justify-content': 'center',
			'text-align': 'center'
		}
		
	# Align Items
	def items_stretch do {'align-items': 'stretch' }
	def items_start do {'align-items': 'flex-start' }
	def items_center do {'align-items': 'center' }
	def items_end do {'align-items': 'flex-end' }
	def items_baseline do {'align-items': 'baseline' }
		
	# Align Content
	def content_start do {'align-content': 'flex-start' }
	def content_center do {'align-content': 'center' }
	def content_end do {'align-content': 'flex-end' }
	def content_between do {'align-content': 'space-between' }
	def content_around do {'align-content': 'space-around' }
	
	# Align Self
	def self_auto do {'align-self': 'auto' }
	def self_start do {'align-self': 'flex-start' }
	def self_center do {'align-self': 'center' }
	def self_end do {'align-self': 'flex-end' }
	def self_stretch do {'align-self': 'stretch' }
		
	# Justify Content
	def justify_start do {'justify-content': 'flex-start' }
	def justify_center do {'justify-content': 'center' }
	def justify_end do {'justify-content': 'flex-end' }
	def justify_between do {'justify-content': 'space-between' }
	def justify_around do {'justify-content': 'space-around' }
		
	# Flex
	def flex_initial do {flex: '0 1 auto' }
	def flex_1 do {flex: '1 1 0%' }
	def flex_auto do {flex: '1 1 auto' }
	def flex_none do {flex: 'none' }
	def flexible do {flex: '1 1 auto' }
		
	# Flex grow
	def flex_grow(v = 1) do {'flex-grow': v }
	# TODO alias as grow?
	
	# Flex Shrink
	def flex_shrink(v = 1) do {'flex-shrink': v }
	# TODO alias as shrink?
	
	def hsc
		{
			'display': 'flex'
			'flex-direction': 'row'
			'justify-content': 'flex-start'
			'align-items': 'center'
		}
	
	def vsc
		{
			'display': 'flex'
			'flex-direction': 'column'
			'justify-content': 'flex-start'
			'align-items': 'center'
		}
		
	def vss
		{
			'display': 'flex'
			'flex-direction': 'column'
			'justify-content': 'flex-start'
			'align-items': 'stretch'
		}
	
	
	# Order
	def order_first do {order: -9999}
	def order_last do {order: 9999}
	def order(v=0) do {order: v}
	def order_NUM(v) do order(v) # fix this?


	# add custom things here
	
	# SPACING
	
	# Padding
	def pt(v0,v1) do {'padding-top':    $length(v0)}
	def pl(v0,v1) do {'padding-left':   $length(v0)}
	def pr(v0,v1) do {'padding-right':  $length(v0)}
	def pb(v0,v1) do {'padding-bottom': $length(v0)}
	def px(l,r=l) do {'padding-left': $length(l), 'padding-right': $length(r)}
	def py(t,b=t) do {'padding-top': $length(t), 'padding-bottom': $length(b)}
	def p(t,r=t,b=t,l=r)
		{
			'padding-top': $length(t),
			'padding-right': $length(r),
			'padding-bottom': $length(b),
			'padding-left': $length(l)
		}
	
	# Margin
	def mt(v0) do {'margin-top':    $length(v0)}
	def ml(v0) do {'margin-left':   $length(v0)}
	def mr(v0) do {'margin-right':  $length(v0)}
	def mb(v0) do {'margin-bottom': $length(v0)} 
	def mx(l,r=l) do {'margin-left': $length(l), 'margin-right': $length(r)}
	def my(t,b=t) do {'margin-top': $length(t), 'margin-bottom': $length(b)}
	def m(t,r=t,b=t,l=r)
		{
			'margin-top': $length(t),
			'margin-right': $length(r),
			'margin-bottom': $length(b),
			'margin-left': $length(l)
		}

	# Space Between
	def space_x length
		{"& > * + *": {'margin-left': $length(length)}}
	
	def space_y length
		{"& > * + *": {'margin-top': $length(length)}}
		
	def space length
		{
			"padding": $length(length / 2)
			"& > *": {'margin': $length(length / 2) }
		}
		
	
	
	# SIZING
	
	# Width
	def w(length) do  {'width': $length(length)}
	def width(length) do  {'width': $length(length)}
	def wmin(length) do  {'min-width': $length(length)}
	def wmax(length) do  {'max-width': $length(length)}
		
	# Min-Width
	# Max-Width
		
	# Height
	def h(length) do {'heigth': $length(length)}
	def height(length) do {'heigth': $length(length)}
	def hmin(length) do {'min-heigth': $length(length)}
	def hmax(length) do {'max-heigth': $length(length)}
	# Add hclamp ? 

	# Min-Height
	# Max-Height
	
	# Both
	def wh(w,h=w) do {'width': $length(w), 'height': $length(h)}
	def size(w,h=w) do {'width': $length(w), 'height': $length(h)}
	


	# TYPOGRAPHY
	
	# Font Family
	
	def font_sans
		{'font-family': 'system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji"'}
	
	def font_serif
		{'font-family': 'Georgia, Cambria, "Times New Roman", Times, serif'}
	
	def font_mono
		{'font-family': 'Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace'}
	
	
	# Font Size
	# font sizes need to be predefined somewhere outside of this - in theme?
	def text_xs do {'font-size': '.75rem'}
	def text_sm do {'font-size': '.875rem'}
	def text_base do {'font-size': '1rem'}
	def text_lg do {'font-size': '1.125rem'}
	def text_xl do {'font-size': '1.25rem'}
	def text_2xl do {'font-size': '1.5rem'}
	def text_3xl do {'font-size': '1.875rem'}
	def text_4xl do {'font-size': '2.25rem'}
	def text_5xl do {'font-size': '3rem'}
	def text_6xl do {'font-size': '4rem'}
	def text_size v do {'font-size': v}
	
	# Font Smoothing
	def antialiased
		{
			'-webkit-font-smoothing': 'antialiased'
			'-moz-osx-font-smoothing': 'grayscale'
		}
	
	def subpixel_antialiased
		{
			'-webkit-font-smoothing': 'auto'
			'-moz-osx-font-smoothing': 'auto'
		}
	
	
	# Font Style
	def italic do {'font-style': 'italic'}
	def not_italic do {'font-style': 'normal'}
	
	
	# Font Weight
	def font_hairline do {'font-weight': 100}
	def font_thin do {'font-weight': 200}
	def font_light do {'font-weight': 300}
	def font_normal do {'font-weight': 400}
	def font_medium do {'font-weight': 500}
	def font_semibold do {'font-weight': 600}
	def font_bold do {'font-weight': 700}
	def font_extrabold do {'font-weight': 800}
	def font_black do {'font-weight': 900}
	
	
	# Letter Spacing
	# Add 'ls' alias?
	def tracking_tighter do {'letter-spacing': '-0.05em' }
	def tracking_tight do {'letter-spacing': '-0.025em' }
	def tracking_normal do {'letter-spacing': '0' }
	def tracking_wide do {'letter-spacing': '0.025em' }
	def tracking_wider do {'letter-spacing': '0.05em' }
	def tracking_widest do {'letter-spacing': '0.1em' }
	
	
	# Line Height
	# Add 'lh' alias?
	def leading_none do {'line-height': '1' }
	def leading_tight do {'line-height': '1.25' }
	def leading_snug do {'line-height': '1.375' }
	def leading_normal do {'line-height': '1.5' }
	def leading_relaxed do {'line-height': '1.625' }
	def leading_loose do {'line-height': '2' }
			
	# should this use rems by default? How would you do
	# plain numeric values?
	def leading value do {'line-height': $length(value)}
	def lh value do {'line-height': value}
	
	
	# List Style Type
	def list_none do {'list-style-type': 'none' }
	def list_disc do {'list-style-type': 'disc' }
	def list_decimal do {'list-style-type': 'decimal' }
		
		
	# List Style Position
	def list_inside do {'list-style-position': 'inside' }
	def list_outside do {'list-style-position': 'outside' }
	
	
	# Placeholder Color
	
	# Placeholder Opacity
	
	def ph_opacity alpha
		{'--ph-alpha': $alpha(alpha)}
	
	def ph_COLOR color, alpha
		{
			'&::placeholder': {
				color: color.string.replace('--alpha','--ph-alpha')
			},
			'--ph-alpha': $alpha(alpha)
		}

	
	# Text Align
	def text_left do {'text-align': 'left' }
	def text_center do {'text-align': 'center' }
	def text_right do {'text-align': 'right' }
	def text_justify do {'text-align': 'justify' }

	
	# Text Color
	
	def COLOR color, alpha
		{
			'color': color.string.replace('--alpha','--text-alpha'),
			'--text-alpha': $alpha(alpha)
		}
	
	# text opacity
	# TODO add shorthand?
	def text_opacity alpha
		{
			'--text-alpha': $alpha(alpha)
		}
	
	# text decoration
	def underline
		{'text-decoration': 'underline'}
	
	def line_through
		{'text-decoration': 'line-through'}
		
	def no_underline
		{'text-decoration': 'none'}
	
	# text transform
	def uppercase
		{'text-transform': 'uppercase'}
	
	def lowercase
		{'text-transform': 'lowercase'}
		
	def capitalize
		{'text-transform': 'capitalize'}
	
	def normal_case
		{'text-transform': 'normal-case'}
		
	
	# vertical align
	def align_baseline
		{'vertical-align': 'baseline'}
	
	def align_top
		{'vertical-align': 'top'}
		
	def align_middle
		{'vertical-align': 'middle'}
		
	def align_bottom
		{'vertical-align': 'bottom'}
		
	def align_text_top
		{'vertical-align': 'text-top'}
	
	def align_text_bottom
		{'vertical-align': 'text-bottom'}
		
	# whitespace
	def whitespace_normal
		{'white-space': 'whitespace-normal'}
	
	def whitespace_no_wrap
		{'white-space': 'whitespace-no-wrap'}
	
	def whitespace_pre
		{'white-space': 'whitespace-pre'}
	
	def whitespace_pre_line
		{'white-space': 'whitespace-pre-line'}
	
	def whitespace_pre_wrap
		{'white-space': 'whitespace-pre-wrap'}
		
	# word break
	def break_normal
		{'word-break': 'normal', 'overflow-wrap': 'normal'}
	
	def break_words
		{'overflow-wrap': 'break-word'}
	
	def break_all
		{'word-break': 'break-all'}
		
	def truncate
		{'overflow': 'hidden','text-overflow':'ellipsis','white-space':'nowrap'}

	# BACKGRONUDS
	
	# Background Attachment
	
	def bg_fixed do {'background-attachment': 'fixed' }
	def bg_local do {'background-attachment': 'local' }
	def bg_scroll do {'background-attachment': 'scroll' }
	
	# Background Color
	
	def bg_COLOR color, alpha
		{
			'background-color': color.string.replace('--alpha','--bg-alpha')
			'--bg-alpha': $alpha(alpha)
		}
		
	# Background Opacity
	
	def bg_opacity alpha
		{'--bg-alpha': $alpha(alpha)}
		
	# Background Position
	
	def bg_bottom do {'background-position': 'bottom' }
	def bg_center do {'background-position': 'center' }
	def bg_left do {'background-position': 'left' }
	def bg_left_bottom do {'background-position': 'left bottom' }
	def bg_left_top do {'background-position': 'left top' }
	def bg_right do {'background-position': 'right' }
	def bg_right_bottom do {'background-position': 'right bottom' }
	def bg_right_top do {'background-position': 'right top' }
	def bg_top do {'background-position': 'top' }
	
	# Background Repeat
	def bg_repeat do {'background-repeat': 'repeat' }
	def bg_no_repeat do {'background-repeat': 'no-repeat' }
	def bg_repeat_x do {'background-repeat': 'repeat-x' }
	def bg_repeat_y do {'background-repeat': 'repeat-y' }
	def bg_repeat_round do {'background-repeat': 'round' }
	def bg_repeat_space do {'background-repeat': 'space' }
	
	# Background Size
	def bg_auto do {'background-size': 'auto' }
	def bg_cover do {'background-size': 'cover' }
	def bg_contain do {'background-size': 'contain' }
	
	# BORDERS
	
	# radius
	
	def round
		{'border-radius': '9999px'}
		
	def rounded num
		{'border-radius': $radius(num)}
	
	# width
	
	def border value = '1px'
		{'border-width': value}
	
	# color
	
	def border_COLOR color, alpha
		{
			'border-color': color.string.replace('--alpha','--border-alpha')
			'--border-alpha': $alpha(alpha)
		}
		
	
	# opacity
	
	def border_opacity alpha
		{'--border-alpha': $alpha(alpha)}
	
	# style
	def border_solid do	{'border-style': 'solid'}
	def border_dashed do {'border-style': 'dashed'}
	def border_dotted do {'border-style': 'dotted'}
	def border_double do {'border-style': 'double'}
	def border_none do {'border-style': 'none'}
		
	# should also support arbitrary border-(sides) methods
	
	# divide uses selector like spacing
	
	# Tables
	
	# Border Collapse
	
	# Table Layout
	
	
	# EFFECTS
	
	# Box Shadow
	def shadow value
		{'box-shadow': $value(value,variants.shadow)}
	
	# Opacity
	def opacity value
		console.log 'called opacity',value,variants.opacity
		{'opacity': $value(value,variants.opacity)}
	
	# Interactivity
	
	def select_none
		{'user-select': 'none'}
		
	def select_text
		{'user-select': 'text'}
	
	def select_all
		{'user-select': 'all'}
		
	def select_auto
		{'user-select': 'auto'}
	
	# space between .space-x-0 > * + *
	# def space-x num
	
	
	# INTERACTIVITY

	# Cursor	
	def cursor_auto do {cursor: 'auto' }
	def cursor_default do {cursor: 'default' }
	def cursor_pointer do {cursor: 'pointer' }
	def cursor_wait do {cursor: 'wait' }
	def cursor_text do {cursor: 'text' }
	def cursor_move do {cursor: 'move' }
	def cursor_not_allowed do {cursor: 'not-allowed' }

	# SVG
	
	# Fill
	
	# Stroke
	
	def stroke_COLOR color, alpha
		{
			'stroke': color.string.replace('--alpha','stroke-alpha')
			'--stroke-alpha': $alpha(alpha)
		}
		
	# Stroke Width

export class StyleRule
	
	def constructor context,states,modifiers
		context = context
		states = states
		selector = Selectors.parse(context,states)
		rules = modifiers isa Array ? Rules.parse(modifiers) : modifiers
		selectors = {}
		
	def toString
		let sel = selector
		let parts = []
		let subselectors = {}
		let subrules = []

		for own key,value of rules
			continue if value == undefined
			
			let subsel = null
			
			if key[0] == '['
				let substates = states.concat(JSON.parse(key))
				subrules.push StyleRule.new(context,substates,value)
				continue

			if key.indexOf('&') >= 0
				console.log 'key',key
				let substates = states.concat([[key]])
				subrules.push StyleRule.new(context,substates,value)
				continue

				subsel = key.replace('&',sel)

				let sub = subselectors[subsel] ||= []
				for own subkey,subvalue of value
					unless subvalue == undefined
						sub.push "{subkey}: {subvalue};"
			else				
				parts.push "{key}: {value};"

		let out = sel + ' {\n' + parts.join('\n') + '\n}'
		out += '}' if sel.indexOf('@media') >= 0
		
		for own subsel,contents of subselectors
			let subout = subsel + ' {\n' + contents.join('\n') + '\n}'
			subout += '}' if subsel.indexOf('@media') >= 0	
			out += '\n' + subout
		
		for own subrule in subrules
			out += '\n' + subrule.toString()

		return out



###

:active
:any-link
:checked
:blank
:default
:defined
:dir()
:disabled
:empty
:enabled
:first
:first-child
:first-of-type
:fullscreen
:focus
:focus-visible
:focus-within
:has()
:host()
:host-context()
:hover
:indeterminate
:in-range
:invalid
:is() (:matches(), :any())
:lang()
:last-child
:last-of-type
:left
:link
:not()
:nth-child()
:nth-last-child()
:nth-last-of-type()
:nth-of-type()
:only-child
:only-of-type
:optional
:out-of-range
:placeholder-shown
:read-only
:read-write
:required
:right
:root
:scope
:target
:valid
:visited
:where()

###