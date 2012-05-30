--  
--  Copyright 2012 Two Lives Left Pty. Ltd.
--  
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--  
--  http://www.apache.org/licenses/LICENSE-2.0
--  
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
--  

-- This file is loaded before any user scripts, removing unsafe environment functions

------------------------------------------------
-- Block out any dangerous or insecure functions
------------------------------------------------

arg=nil

setfenv=nil
getfenv=nil
string.dump=nil
dofile=nil
io={write=io.write}

load=nil
loadfile=nil

os.execute=nil
os.getenv=nil
os.remove=nil
os.rename=nil
os.tmpname=nil
os.exit=nil

--[[
-- We allow:
os.time
os.setlocale
os.difftime
os.date
os.clock
--]]

package.loaded.io=io
package.loaded.package=nil
package=nil
require=nil
