#!/usr/bin/env ruby
require 'irb'

$: << File.expand_path(File.join(File.dirname(__FILE__), '../lib'))
require 'ubnt'
require 'ubnt/configuration'
require 'ubnt/device'
require 'ubnt/locator'
require 'ubnt/provisioner'
require 'ubnt/staticarp'

IRB.start
