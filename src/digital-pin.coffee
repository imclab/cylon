###
 * Linux IO DigitalPin
 * cylonjs.com
 *
 * Copyright (c) 2013 The Hybrid Group
 * Licensed under the Apache 2.0 license.
###

'use strict';


FS = require('fs')
EventEmitter = require('events').EventEmitter

namespace = require 'node-namespace'

# IO is class that lays foundation to DigitalPin and I2C in Raspi and beaglebone.
#
namespace 'Cylon.IO', ->
  class @DigitalPin extends EventEmitter

    GPIO_PATH = "/sys/class/gpio"
    GPIO_DIRECTION_READ = "in"
    GPIO_DIRECTION_WRITE = "out"
    HIGH = 1
    LOW = 0

    constructor: (opts) ->
      @self = this
      @pinNum = opts.pin
      @status = 'low'
      @ready = false

    open: (mode) ->
      # Creates the GPIO file to read/write from
      FS.writeFile("#{ GPIO_PATH }/export", "#{ @pinNum }", (err) ->
        unless(err)
          @self.emit('create')
          @_setMode(opts.mode)
        else
          console.log('Error while creating pin files ...')
          @self.emit('error', 'Error while creating pin files')
      )


    digitalWrite: (value) ->
      @_setMode('w') unless @mode == 'w'
      @status = if (value == 1) then 'high' else 'low'

      FS.writeFile(@pinFile, value, (err) ->
        if (err)
          console.log('ERROR occurred while writing to the Pin File')
          @emit('error', "Error occurred while writing value #{ value } to pin #{ @pinNum }")
        else
          console.log('Pin File written successfully')
          @emit('digitalWrite', value)
      )

    digitalRead: ->
      @_setMode('r') unless @mode == 'r'
      readData = null

      FS.readFile(@pinFile, (err, data) ->
        if err
          console.log('ERROR occurred while reading from the Pin')
          @emit('error', "Error occurred while reading from pin #{ @pinNum }")
        else
          readData = data
          @emit('read', data)
      )

      readData

    # Sets the mode for the GPIO pin by writing the correct values to the pin reference files
    _setMode: (mode) ->
      @mode = mode
      if @mode == 'w'
        FS.writeFile("#{ GPIO_PATH }/gpio#{ @pinNum }/direction", GPIO_DIRECTION_WRITE, (err) ->
          unless (err)
            console.log('Pin mode(direction) setup...')
            @pinFile = "#{ GPIO_PATH }/gpio#{ @pinNum }/value"
            @ready = true
            @emit('open', mode)
          else
            console.log('Error occurred while settingup pin mode(direction)...')
            @emit('error', "Setting up pin direction failed")
        )
      else if mode =='r'
        FS.writeFile("#{ GPIO_PATH }/gpio#{ @pinNum }/direction", GPIO_DIRECTION_READ, (err) ->
          unless (err)
            console.log('Pin mode(direction) setup...')
            @pinFile = "#{ GPIO_PATH }/gpio#{ @pinNum }/value"
            @ready = true
            @emit('open', mode)
          else
            console.log('Error occurred while settingup pin mode(direction)...')
            @emit('error', "Setting up pin direction failed")
        )

    on: ->
      @digitalWrite(1)

    off: ->
      @digitalWrite(0)

    toggle: ->
      if @status == 'low'
        @digitalWrite(1)
      else
        @digitalWrite(0)

    isOn:
      (@status == 'high')

    isOff:
      !@isOn     