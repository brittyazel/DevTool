-- DevTool is a World of Warcraft® addon development tool.
-- Copyright (c) 2021-2023 Britt W. Yazel
-- Copyright (c) 2016-2021 Peter Varren
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ... --make use of the default addon namespace
local ViragDevTool = addonTable.ViragDevTool

--- Linked List
-- @field first
-- @field last
--
-- Each node has:
-- @field name - string name
-- @field value - any object
-- @field next - nil/next node
-- @field padding - int expanded level( when you click on table it expands  so padding = padding + 1)
-- @field parent - parent node after it expanded
-- @field expanded - true/false/nil

ViragDevTool.LinkedList = {}

function ViragDevTool.LinkedList:new()
	return setmetatable({ length = 0 }, { __index = self })
end

function ViragDevTool.LinkedList:GetInfoAtPosition(position)
	if self.length < position or self.first == nil then
		return nil
	end

	local currNode = self.first
	for _ = 1, position do
		currNode = currNode.next
		if not currNode then
			return nil
		end
	end

	return currNode
end

function ViragDevTool.LinkedList:AddNodesAfter(nodeList, parentNode)
	local tempNext = parentNode.next
	local currNode = parentNode;

	for _, node in pairs(nodeList) do
		currNode.next = node
		currNode = node
		self.length = self.length + 1
	end

	currNode.next = tempNext

	if tempNext == nil then
		self.last = currNode
	end
end

function ViragDevTool.LinkedList:AddNode(data, dataName)
	local node = self:NewNode(data, dataName)

	if self.first == nil then
		self.first = node
		self.last = node
	else
		if self.last ~= nil then
			self.last.next = node
		end
		self.last = node
	end

	self.length = self.length + 1
end

function ViragDevTool.LinkedList:NewNode(data, dataName, padding, parent)
	return {
		name = dataName,
		value = data,
		next = nil,
		padding = padding == nil and 0 or padding,
		parent = parent
	}
end

function ViragDevTool.LinkedList:RemoveChildNodes(node)
	local currNode = node

	while true do
		currNode = currNode.next
		if currNode == nil then
			node.next = nil
			self.last = node
			break
		end
		if currNode.padding <= node.padding then
			node.next = currNode
			break
		end
	end

	self.length = self.length - 1
end

function ViragDevTool.LinkedList:Clear()
	local currNode = self.first

	while currNode do
		local nextNode = currNode.next
		currNode.next = nil
		currNode = nextNode
	end

	self.length = 0
	self.first = nil
	self.last = nil
	collectgarbage("collect")
end
