
var paths = require.context('raw-loader!./apps', true, /[\w\-\/]+\.imba$/)
var examples = {}

for src in paths.keys()
	let path = "apps/" + src.slice(2)
	var example = {
		path: path
		body: paths(src).default
	}
	examples[path] = example

console.log "examples",examples

var compiler = require('../src/compiler/compiler.imba1')

require('../src/imba/index.imba')
require('./spec.imba')

global.imba.compiler = compiler

var exposed = {}

window.onerror = do |e|
	console.log('page:error',{message: (e.message or e)})

window.onunhandledrejection = do |e|
	console.log('page:error',{message: e.reason.message})

var afterRun = do
	if SPEC.blocks.length
		exposed.test = SPEC.run.bind(SPEC)

		for block in SPEC.blocks
			exposed[block.name] = do block.run()

	imba.commit()
	console.log('loaded?')

var run = do |js|
	# hack until we changed implicit self behaviour
	# js = js.replace('self = {}','self = SELF')
	let script = document.createElement('script')
	script.innerHTML = js
	# script.onload = afterRun
	document.head.appendChild(script)
	afterRun()
	# window.eval(js)
	# afterRun()
	

var compileAndRun = do |example|
	
	try
		var result = compiler.compile(example.body,{
			sourcePath: example.path,
			runtime: 'global',
			platform: 'browser'
		})
		var js = result.js
		run(js)
	catch e
		console.log('page:error',{message: e.message})
		# console.log('compilation error')


var load = do |src|
	if !global.location.origin.startsWith('file://')
		let script = document.createElement('script')
		script.type = 'module'
		script.src = './' + src.replace('.imba','.js')
		script.onload = afterRun
		document.head.appendChild(script)
	elif examples[src]
		compileAndRun(examples[src])

tag test-runner

	def go e
		document.location.hash = "#{e.target.value}"
		document.location.reload()

	def call e
		exposed[e.target.value]()
		self

	def render
		<self>
			<select @change.go>
				<option disabled=yes value=""> "Jump to example"
				for src in Object.keys(examples)
					<option> src

			for name in Object.keys(exposed)
				<button value=name @click.call> name

# imba.mount(<test-runner>)

var hash = (document.location.hash || '').slice(1)
if hash
	load(hash)

# window.onload = do
# 	console.log('example:loaded')
# 	# var hash = (document.location.hash || '').slice(1)
# 	# load(hash) if hash