local timer = class:create("timer")

function timer.public:create(...)
    if self ~= timer.public then return false end
    local cTimer = self:createInstance()
    if cTimer and not cTimer:load(...) then
        cTimer:destroyInstance()
        return false
    end
    return cTimer
end

function timer.public:destroy(...)
    if not timer.public:isInstance(self) then return false end
    return self:unload(...)
end

function timer.public:load(exec, interval, executions, ...)
    if not timer.public:isInstance(self) then return false end
    interval, executions = tonumber(interval), tonumber(executions)
    if not exec or (type(exec) ~= "function") or not interval or not executions then return false end
    interval, executions = math.max(1, interval), math.max(0, executions)
    self.exec = exec
    self.currentExec = 0
    self.interval, self.executions = interval, executions
    self.arguments = {...}
    self.timer = setTimer(function()
        self.currentExec = self.currentExec + 1
        if (self.executions > 0) and (self.currentExec >= self.executions) then
            self:destroy()
        end
        self.exec(unpack(self.arguments))
    end, self.interval, self.executions)
    return self
end

function timer.public:unload()
    if not timer.public:isInstance(self) then return false end
    if self.timer and isTimer(self.timer) then
        killTimer(self.timer)
    end
    self:destroyInstance()
    return true
end
