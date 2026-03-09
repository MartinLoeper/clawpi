package eww

import (
	"fmt"
	"log"
	"os/exec"
	"strings"
	"sync"
)

type State string

const (
	StateIdle         State = "idle"
	StateThinking     State = "thinking"
	StateResponding   State = "responding"
	StateToolUse      State = "tool_use"
	StateError        State = "error"
	StateDisconnected State = "disconnected"
)

type Controller struct {
	configDir string
	mu        sync.Mutex
	state     State
}

func NewController(configDir string) *Controller {
	return &Controller{
		configDir: configDir,
		state:     StateIdle,
	}
}

func (c *Controller) SetState(state State) {
	c.mu.Lock()
	prev := c.state
	c.state = state
	c.mu.Unlock()

	if state == prev {
		return
	}

	log.Printf("state: %s -> %s", prev, state)
	c.update("clawpi_state", string(state))

	if state == StateIdle {
		c.ewwCmd("close", "status-overlay")
	} else if prev == StateIdle {
		c.ewwCmd("open", "status-overlay")
	}
}

func (c *Controller) SetToolName(name string) {
	c.update("clawpi_tool_name", name)
}

func (c *Controller) SetMessage(msg string) {
	c.update("clawpi_message", msg)
}

func (c *Controller) update(variable, value string) {
	arg := fmt.Sprintf("%s=%s", variable, value)
	if err := c.ewwCmd("update", arg); err != nil {
		log.Printf("eww update %s: %v", arg, err)
	}
}

func (c *Controller) ewwCmd(args ...string) error {
	fullArgs := append([]string{"--config", c.configDir}, args...)
	cmd := exec.Command("eww", fullArgs...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("%s: %s", strings.Join(args, " "), strings.TrimSpace(string(output)))
	}
	return nil
}
