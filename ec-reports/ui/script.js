// Global variables
let isAdmin = false;
let currentTicket = null;
let categories = [];
let priorities = [];
let theme = 'dark';
let accentColor = '#8A2BE2';
let fontSize = 'medium';
let playerName = 'Player';

// Initialize the application
document.addEventListener('DOMContentLoaded', function() {
    // Set up event listeners
    setupEventListeners();
});

// Set up all event listeners
function setupEventListeners() {
    // Close button
    document.getElementById('close-btn').addEventListener('click', function(e) {
        e.preventDefault();
        e.stopPropagation();
        console.log("Close button clicked");
        closeMenu();
    });    
    // Menu items
    const menuItems = document.querySelectorAll('.menu-item');
    menuItems.forEach(item => {
        item.addEventListener('click', () => {
            const section = item.getAttribute('data-section');
            switchSection(section);
        });
    });
    
    // Bug report form submission
    document.getElementById('bug-report-form').addEventListener('submit', submitBugReport);
    
    // Player report form submission
    document.getElementById('player-report-form').addEventListener('submit', submitPlayerReport);
    
    // Close modal
    document.querySelector('.close-modal').addEventListener('click', closeModal);
    
    // Submit response
    document.getElementById('submit-response').addEventListener('click', submitResponse);
    
    // Admin actions
    document.getElementById('assign-ticket').addEventListener('click', assignTicket);
    
    // Teleport to location
    document.getElementById('teleport-to-location').addEventListener('click', teleportToLocation);
    
    // Status dropdown
    const statusItems = document.querySelectorAll('#status-dropdown .dropdown-item');
    statusItems.forEach(item => {
        item.addEventListener('click', () => {
            const status = item.getAttribute('data-status');
            updateTicketStatus(status);
        });
    });
    
    // Toggle dropdowns
    const dropdownToggles = document.querySelectorAll('.dropdown-toggle');
    dropdownToggles.forEach(toggle => {
        toggle.addEventListener('click', (e) => {
            const dropdown = toggle.nextElementSibling;
            dropdown.classList.toggle('active');
            e.stopPropagation();
        });
    });
    
    // Close dropdowns when clicking outside
    document.addEventListener('click', () => {
        const dropdowns = document.querySelectorAll('.dropdown-menu');
        dropdowns.forEach(dropdown => {
            dropdown.classList.remove('active');
        });
    });
    
    // Search functionality
    document.getElementById('my-tickets-search').addEventListener('input', () => {
        filterTickets('my-tickets-list', 'my-tickets-search', 'my-tickets-filter');
    });
    
    document.getElementById('admin-tickets-search').addEventListener('input', () => {
        filterAdminTickets();
    });
    
    // Filters
    document.getElementById('my-tickets-filter').addEventListener('change', () => {
        filterTickets('my-tickets-list', 'my-tickets-search', 'my-tickets-filter');
    });
    
    document.getElementById('admin-status-filter').addEventListener('change', filterAdminTickets);
    document.getElementById('admin-priority-filter').addEventListener('change', filterAdminTickets);
    document.getElementById('admin-type-filter').addEventListener('change', filterAdminTickets);
    
    // ESC key to close
    document.addEventListener('keyup', function(event) {
        if (event.key === 'Escape') {
            if (document.getElementById('ticket-details-modal').classList.contains('active')) {
                closeModal();
            } else {
                closeMenu();
            }
        }
    });
}

// Switch between sections
function switchSection(sectionId) {
    // Update menu items
    const menuItems = document.querySelectorAll('.menu-item');
    menuItems.forEach(item => {
        if (item.getAttribute('data-section') === sectionId) {
            item.classList.add('active');
        } else {
            item.classList.remove('active');
        }
    });
    
    // Update sections
    const sections = document.querySelectorAll('.section');
    sections.forEach(section => {
        if (section.id === sectionId) {
            section.classList.add('active');
        } else {
            section.classList.remove('active');
        }
    });
    
    // Update header title
    const sectionTitle = document.getElementById('section-title');
    switch (sectionId) {
        case 'bug-report':
            sectionTitle.textContent = 'Bug Report';
            break;
        case 'player-report':
            sectionTitle.textContent = 'Player Report';
            break;
        case 'my-tickets':
            sectionTitle.textContent = 'My Tickets';
            fetchMyTickets();
            break;
        case 'admin-panel':
            sectionTitle.textContent = 'Admin Panel';
            if (isAdmin) {
                fetchAllTickets();
                updateAdminStats();
            }
            break;
    }
}

// Submit a bug report
function submitBugReport(e) {
    e.preventDefault();
    
    const location = document.getElementById('bug-location').value;
    const subject = document.getElementById('bug-subject').value;
    const description = document.getElementById('bug-description').value;
    const reproduce = document.getElementById('bug-reproduce').value;
    
    // Validate
    if (!subject || !description) {
        showNotification('Please fill in all required fields', 'error');
        return;
    }
    
    if (subject.length < 3) {
        showNotification('Subject is too short', 'error');
        return;
    }
    
    if (description.length < 10) {
        showNotification('Please provide more details in the description', 'error');
        return;
    }
    
    // Send to server
    fetch(`https://${GetParentResourceName()}/submitReport`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            category: 'bug',
            subject: subject,
            description: `Location: ${location}\n\n${description}\n\nSteps to Reproduce: ${reproduce || 'Not provided'}`
        })
    });
    
    // Clear form
    document.getElementById('bug-location').value = '';
    document.getElementById('bug-subject').value = '';
    document.getElementById('bug-description').value = '';
    document.getElementById('bug-reproduce').value = '';
    
    showNotification('Bug report submitted successfully', 'success');
}

// Submit a player report
function submitPlayerReport(e) {
    e.preventDefault();
    
    const playerId = document.getElementById('player-id').value;
    const reason = document.getElementById('report-reason').value;
    const description = document.getElementById('player-description').value;
    const evidence = document.getElementById('player-evidence').value;
    
    // Validate
    if (!playerId || !reason || !description) {
        showNotification('Please fill in all required fields', 'error');
        return;
    }
    
    if (description.length < 10) {
        showNotification('Please provide more details in the description', 'error');
        return;
    }
    
    // Send to server
    fetch(`https://${GetParentResourceName()}/submitReport`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            category: 'player',
            subject: `Player Report: ${playerId} - ${reason}`,
            description: `Reported Player: ${playerId}\nReason: ${reason}\n\n${description}\n\nEvidence: ${evidence || 'Not provided'}`
        })
    });
    
    // Clear form
    document.getElementById('player-id').value = '';
    document.getElementById('report-reason').value = '';
    document.getElementById('player-description').value = '';
    document.getElementById('player-evidence').value = '';
    
    showNotification('Player report submitted successfully', 'success');
}

// Fetch my tickets
function fetchMyTickets() {
    fetch(`https://${GetParentResourceName()}/getMyTickets`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

// Fetch all tickets (admin only)
function fetchAllTickets() {
    if (!isAdmin) return;
    
    fetch(`https://${GetParentResourceName()}/getAllActiveTickets`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

// Update admin dashboard stats
function updateAdminStats() {
    if (!isAdmin) return;
    
    fetch(`https://${GetParentResourceName()}/getAdminStats`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

// View ticket details
function viewTicket(ticketId) {
    fetch(`https://${GetParentResourceName()}/viewTicket`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            ticketId
        })
    });
    
    // Open modal
    document.getElementById('ticket-details-modal').classList.add('active');
}

// Submit a response to a ticket
function submitResponse() {
    if (!currentTicket) return;
    
    const message = document.getElementById('response-text').value;
    
    if (!message || message.trim() === '') {
        showNotification('Please enter a response', 'error');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/addResponse`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            ticketId: currentTicket.ticket_id,
            message: message
        })
    });
    
    // Clear input
    document.getElementById('response-text').value = '';
}

// Assign ticket to self (admin only)
function assignTicket() {
    if (!currentTicket || !isAdmin) return;
    
    fetch(`https://${GetParentResourceName()}/assignTicket`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            ticketId: currentTicket.ticket_id
        })
    });
}

// Teleport to location (admin only)
function teleportToLocation() {
    if (!currentTicket || !isAdmin) return;
    
    fetch(`https://${GetParentResourceName()}/teleportToLocation`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            ticketId: currentTicket.ticket_id
        })
    });
    
    closeModal();
    closeMenu();
}

// Update ticket status (admin only)
function updateTicketStatus(status) {
    if (!currentTicket || !isAdmin) return;
    
    fetch(`https://${GetParentResourceName()}/updateTicketStatus`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            ticketId: currentTicket.ticket_id,
            status: status
        })
    });
}

// Update ticket priority (admin only)
function updateTicketPriority(priority) {
    if (!currentTicket || !isAdmin) return;
    
    fetch(`https://${GetParentResourceName()}/updateTicketPriority`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            ticketId: currentTicket.ticket_id,
            priority: priority
        })
    });
}

// Filter tickets in the list
function filterTickets(listId, searchId, filterId) {
    const searchTerm = document.getElementById(searchId).value.toLowerCase();
    const statusFilter = document.getElementById(filterId).value;
    
    const ticketItems = document.querySelectorAll(`#${listId} .ticket-item`);
    
    ticketItems.forEach(item => {
        const title = item.querySelector('.ticket-title').textContent.toLowerCase();
        const description = item.getAttribute('data-description').toLowerCase();
        const status = item.getAttribute('data-status');
        
        const matchesSearch = title.includes(searchTerm) || description.includes(searchTerm);
        const matchesStatus = statusFilter === 'all' || status === statusFilter;
        
        if (matchesSearch && matchesStatus) {
            item.style.display = 'block';
        } else {
            item.style.display = 'none';
        }
    });
    
    // Check if any tickets are visible
    const visibleTickets = document.querySelectorAll(`#${listId} .ticket-item[style="display: block;"]`);
    const emptyState = document.querySelector(`#${listId} .empty-state`);
    
    if (visibleTickets.length === 0 && emptyState) {
        emptyState.style.display = 'flex';
    } else if (emptyState) {
        emptyState.style.display = 'none';
    }
}

// Filter admin tickets with more options
function filterAdminTickets() {
    const searchTerm = document.getElementById('admin-tickets-search').value.toLowerCase();
    const statusFilter = document.getElementById('admin-status-filter').value;
    const priorityFilter = document.getElementById('admin-priority-filter').value;
    const typeFilter = document.getElementById('admin-type-filter').value;
    
    const rows = document.querySelectorAll('#admin-tickets-list tr');
    let visibleCount = 0;
    
    rows.forEach(row => {
        const subject = row.querySelector('td:nth-child(3)').textContent.toLowerCase();
        const status = row.getAttribute('data-status');
        const priority = row.getAttribute('data-priority');
        const type = row.getAttribute('data-type');
        
        const matchesSearch = subject.includes(searchTerm);
        const matchesStatus = statusFilter === 'all' || status === statusFilter;
        const matchesPriority = priorityFilter === 'all' || priority === priorityFilter;
        const matchesType = typeFilter === 'all' || type === typeFilter;
        
        if (matchesSearch && matchesStatus && matchesPriority && matchesType) {
            row.style.display = '';
            visibleCount++;
        } else {
            row.style.display = 'none';
        }
    });
    
    // Show/hide empty state
    const emptyState = document.getElementById('admin-empty-state');
    if (visibleCount === 0) {
        emptyState.style.display = 'flex';
    } else {
        emptyState.style.display = 'none';
    }
}

// Close the menu
function closeMenu() {
    console.log("Closing menu");
    
    // Hide body immediately for visual feedback
    document.body.classList.remove('visible');
    
    // Close any open modals
    document.getElementById('ticket-details-modal').classList.remove('active');
    currentTicket = null;
    
    // Send multiple close requests to ensure it gets through
    sendCloseRequest();
    
    // Send another request after a short delay as backup
    setTimeout(sendCloseRequest, 200);
}

function sendCloseRequest() {
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    }).catch(error => {
        console.error('Error closing UI:', error);
        // Fallback to force close if fetch fails
        window.parent.postMessage({ type: 'ui:close' }, '*');
    });
}

// Close the modal
function closeModal() {
    document.getElementById('ticket-details-modal').classList.remove('active');
    currentTicket = null;
}

// Show notification
function showNotification(message, type = 'info') {
    const notifications = document.getElementById('notifications');
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;
    
    notifications.appendChild(notification);
    
    // Remove after 5 seconds
    setTimeout(() => {
        notification.style.opacity = '0';
        setTimeout(() => {
            if (notifications.contains(notification)) {
                notifications.removeChild(notification);
            }
        }, 300);
    }, 5000);
}

// Update UI with ticket data
function updateTicketsList(tickets, listId) {
    const list = document.getElementById(listId);
    
    // Clear existing tickets except empty state
    const existingTickets = list.querySelectorAll('.ticket-item');
    existingTickets.forEach(ticket => {
        list.removeChild(ticket);
    });
    
    const emptyState = list.querySelector('.empty-state');
    
    if (tickets && tickets.length > 0) {
        // Hide empty state
        if (emptyState) {
            emptyState.style.display = 'none';
        }
        
        // Add tickets
        tickets.forEach(ticket => {
            const ticketElement = createTicketElement(ticket);
            list.appendChild(ticketElement);
        });
    } else {
        // Show empty state
        if (emptyState) {
            emptyState.style.display = 'flex';
        }
    }
}

// Update admin tickets table
function updateAdminTicketsTable(tickets) {
    const tbody = document.getElementById('admin-tickets-list');
    
    // Clear existing rows
    tbody.innerHTML = '';
    
    const emptyState = document.getElementById('admin-empty-state');
    
    if (tickets && tickets.length > 0) {
        // Hide empty state
        if (emptyState) {
            emptyState.style.display = 'none';
        }
        
        // Add tickets
        tickets.forEach(ticket => {
            const row = document.createElement('tr');
            row.setAttribute('data-id', ticket.ticket_id);
            row.setAttribute('data-status', ticket.status);
            row.setAttribute('data-priority', ticket.priority);
            row.setAttribute('data-type', ticket.category);
            
            // Determine ticket type icon and label
            let typeIcon, typeLabel;
            if (ticket.category === 'bug') {
                typeIcon = 'bug';
                typeLabel = 'Bug';
            } else if (ticket.category === 'player') {
                typeIcon = 'user-shield';
                typeLabel = 'Player';
            } else {
                typeIcon = 'question-circle';
                typeLabel = ticket.category;
            }
            row.innerHTML = `
                <td>${ticket.ticket_id}</td>
                <td><i class="fas fa-${typeIcon}"></i> ${typeLabel}</td>
                <td>${ticket.subject}</td>
                <td>${ticket.player_name}</td>
                <td><span class="ticket-status ${ticket.status}">${ticket.status}</span></td>
                <td><span class="ticket-priority ${ticket.priority}">${ticket.priority}</span></td>
                <td>${new Date(ticket.created_at).toLocaleString()}</td>
                <td class="actions">
                    <button class="action-btn view-ticket" title="View Details"><i class="fas fa-eye"></i></button>
                    <button class="action-btn assign-ticket" title="Assign to Me"><i class="fas fa-user-check"></i></button>
                    <button class="action-btn close-ticket" title="Close Ticket"><i class="fas fa-check-circle"></i></button>
                </td>
            `;
            
            // Add event listeners to action buttons
            const viewBtn = row.querySelector('.view-ticket');
            viewBtn.addEventListener('click', () => {
                viewTicket(ticket.ticket_id);
            });
            
            const assignBtn = row.querySelector('.assign-ticket');
            assignBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                fetch(`https://${GetParentResourceName()}/assignTicket`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        ticketId: ticket.ticket_id
                    })
                });
            });
            
            const closeBtn = row.querySelector('.close-ticket');
            closeBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                fetch(`https://${GetParentResourceName()}/updateTicketStatus`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        ticketId: ticket.ticket_id,
                        status: 'closed'
                    })
                });
            });
            
            tbody.appendChild(row);
        });
    } else {
        // Show empty state
        if (emptyState) {
            emptyState.style.display = 'flex';
        }
    }
}

// Create a ticket element for the tickets list
function createTicketElement(ticket) {
    const ticketElement = document.createElement('div');
    ticketElement.className = 'ticket-item';
    ticketElement.setAttribute('data-id', ticket.ticket_id);
    ticketElement.setAttribute('data-status', ticket.status);
    ticketElement.setAttribute('data-priority', ticket.priority);
    ticketElement.setAttribute('data-description', ticket.description);
    
    // Set border color based on priority
    if (ticket.priority === 'urgent') {
        ticketElement.style.borderLeftColor = 'var(--danger-color)';
    } else if (ticket.priority === 'high') {
        ticketElement.style.borderLeftColor = 'var(--warning-color)';
    } else if (ticket.priority === 'low') {
        ticketElement.style.borderLeftColor = 'var(--success-color)';
    }
    
    const header = document.createElement('div');
    header.className = 'ticket-header';
    
    const title = document.createElement('div');
    title.className = 'ticket-title';
    title.textContent = ticket.subject;
    
    const id = document.createElement('div');
    id.className = 'ticket-id';
    id.textContent = `#${ticket.ticket_id}`;
    
    header.appendChild(title);
    header.appendChild(id);
    
    const content = document.createElement('div');
    content.className = 'ticket-content';
    content.textContent = ticket.description.length > 100 ? 
        ticket.description.substring(0, 100) + '...' : 
        ticket.description;
    
    const footer = document.createElement('div');
    footer.className = 'ticket-footer';
    
    const meta = document.createElement('div');
    meta.className = 'ticket-meta';
    meta.textContent = `${new Date(ticket.created_at).toLocaleString()}`;
    
    const status = document.createElement('span');
    status.className = `ticket-status ${ticket.status}`;
    status.textContent = ticket.status;
    
    footer.appendChild(meta);
    footer.appendChild(status);
    
    ticketElement.appendChild(header);
    ticketElement.appendChild(content);
    ticketElement.appendChild(footer);
    
    // Add click event
    ticketElement.addEventListener('click', () => {
        viewTicket(ticket.ticket_id);
    });
    
    return ticketElement;
}

// Update ticket details in modal
function updateTicketDetails(ticket, responses) {
    currentTicket = ticket;
    
    document.getElementById('ticket-id').textContent = `#${ticket.ticket_id}`;
    document.getElementById('ticket-subject').textContent = ticket.subject;
    document.getElementById('ticket-category').textContent = ticket.category;
    document.getElementById('ticket-status').textContent = ticket.status;
    document.getElementById('ticket-status').className = `ticket-status ${ticket.status}`;
    document.getElementById('ticket-priority').textContent = ticket.priority;
    document.getElementById('ticket-priority').className = `ticket-priority ${ticket.priority}`;
    document.getElementById('ticket-description').textContent = ticket.description;
    document.getElementById('ticket-submitter').textContent = ticket.player_name;
    document.getElementById('ticket-date').textContent = new Date(ticket.created_at).toLocaleString();
    
    // Show/hide teleport button based on ticket type
    const teleportBtn = document.getElementById('teleport-to-location');
    if (ticket.category === 'bug' && ticket.description.includes('Location:')) {
        teleportBtn.style.display = 'block';
    } else {
        teleportBtn.style.display = 'none';
    }
    
    // Update responses
    const responsesContainer = document.getElementById('ticket-responses');
    responsesContainer.innerHTML = '';
    
    if (responses && responses.length > 0) {
        responses.forEach(response => {
            const responseElement = document.createElement('div');
            responseElement.className = `response ${response.is_admin ? 'admin' : 'player'}`;
            
            const responseHeader = document.createElement('div');
            responseHeader.className = 'response-header';
            
            const author = document.createElement('div');
            author.className = 'response-author';
            author.textContent = response.responder_name + (response.is_admin ? ' (Admin)' : '');
            
            const time = document.createElement('div');
            time.className = 'response-time';
            time.textContent = new Date(response.created_at).toLocaleString();
            
            responseHeader.appendChild(author);
            responseHeader.appendChild(time);
            
            const content = document.createElement('div');
            content.className = 'response-content';
            content.textContent = response.message;
            
            responseElement.appendChild(responseHeader);
            responseElement.appendChild(content);
            
            responsesContainer.appendChild(responseElement);
        });
    } else {
        const noResponses = document.createElement('div');
        noResponses.className = 'no-responses';
        noResponses.textContent = 'No responses yet.';
        responsesContainer.appendChild(noResponses);
    }
    
    // Scroll to bottom of responses
    responsesContainer.scrollTop = responsesContainer.scrollHeight;
}

// Update admin dashboard stats
function updateDashboardStats(stats) {
    document.getElementById('open-tickets-count').textContent = stats.open || 0;
    document.getElementById('in-progress-tickets-count').textContent = stats.inProgress || 0;
    document.getElementById('urgent-tickets-count').textContent = stats.urgent || 0;
    document.getElementById('closed-tickets-count').textContent = stats.closedToday || 0;
}

// Play notification sound
function playNotificationSound() {
    const audio = document.getElementById('notification-sound');
    audio.play().catch(error => {
        console.error('Error playing notification sound:', error);
    });
}

// NUI Message Handler
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch (data.action) {
        case 'openMenu':
            // Make body visible
            document.body.classList.add('visible');
            
            // Set admin status
            isAdmin = data.isAdmin;
            if (isAdmin) {
                document.querySelectorAll('.admin-only').forEach(el => {
                    el.style.display = 'block';
                });
            }
            
            // Set player name
            playerName = data.playerName || 'Player';
            document.getElementById('user-name').textContent = playerName;
            
            // Set categories
            categories = data.categories;
            
            // Set priorities
            priorities = data.priorities;
            const priorityDropdown = document.getElementById('priority-dropdown');
            priorityDropdown.innerHTML = '';
            priorities.forEach(priority => {
                const item = document.createElement('div');
                item.className = 'dropdown-item';
                item.setAttribute('data-priority', priority.value);
                item.textContent = priority.label;
                item.addEventListener('click', () => {
                    updateTicketPriority(priority.value);
                });
                priorityDropdown.appendChild(item);
            });
            
            // Set theme
            theme = data.theme;
            document.body.className = `theme-${theme} visible`;
            
            // Set accent color
            accentColor = data.accentColor;
            document.documentElement.style.setProperty('--primary-color', accentColor);
            
            // Set font size
            fontSize = data.fontSize;
            document.body.classList.add(`font-${fontSize}`);
            break;
            
        case 'updateMyTickets':
            updateTicketsList(data.tickets, 'my-tickets-list');
            break;
            
        case 'updateAllTickets':
            updateAdminTicketsTable(data.tickets);
            break;
            
        case 'updateAdminStats':
            updateDashboardStats(data.stats);
            break;
            
        case 'showTicketDetails':
            updateTicketDetails(data.ticket, data.responses);
            break;
            
        case 'ticketCreated':
            showNotification(`Ticket #${data.ticketId} created successfully`, 'success');
            // Refresh tickets list
            fetchMyTickets();
            break;
            
        case 'ticketUpdated':
            if (currentTicket && currentTicket.ticket_id === data.ticketId) {
                // Update current ticket with new data
                Object.keys(data.updates).forEach(key => {
                    currentTicket[key] = data.updates[key];
                });
                
                // Update UI
                if (data.updates.status) {
                    document.getElementById('ticket-status').textContent = data.updates.status;
                    document.getElementById('ticket-status').className = `ticket-status ${data.updates.status}`;
                }
                
                if (data.updates.priority) {
                    document.getElementById('ticket-priority').textContent = data.updates.priority;
                    document.getElementById('ticket-priority').className = `ticket-priority ${data.updates.priority}`;
                }
            }
            
            // Refresh tickets lists
            fetchMyTickets();
            if (isAdmin) {
                fetchAllTickets();
                updateAdminStats();
            }
            break;
            
        case 'newResponse':
            if (currentTicket && currentTicket.ticket_id === data.ticketId) {
                // Add new response to UI
                const responsesContainer = document.getElementById('ticket-responses');
                
                const responseElement = document.createElement('div');
                responseElement.className = `response ${data.response.is_admin ? 'admin' : 'player'}`;
                
                const responseHeader = document.createElement('div');
                responseHeader.className = 'response-header';
                
                const author = document.createElement('div');
                author.className = 'response-author';
                author.textContent = data.response.responder_name + (data.response.is_admin ? ' (Admin)' : '');
                
                const time = document.createElement('div');
                time.className = 'response-time';
                time.textContent = new Date(data.response.created_at).toLocaleString();
                
                responseHeader.appendChild(author);
                responseHeader.appendChild(time);
                
                const content = document.createElement('div');
                content.className = 'response-content';
                content.textContent = data.response.message;
                
                responseElement.appendChild(responseHeader);
                responseElement.appendChild(content);
                
                // Remove "no responses" message if it exists
                const noResponses = responsesContainer.querySelector('.no-responses');
                if (noResponses) {
                    responsesContainer.removeChild(noResponses);
                }
                
                responsesContainer.appendChild(responseElement);
                
                // Scroll to bottom
                responsesContainer.scrollTop = responsesContainer.scrollHeight;
            }
            break;
            
        case 'showNotification':
            showNotification(data.message, data.type);
            break;
            
        case 'playNotificationSound':
            playNotificationSound();
            break;
            
        case 'forceClose':
            // Hide body and reset state
            document.body.classList.remove('visible');
            closeModal();
            break;
            
        case 'closeMenu':
            // Hide body
            document.body.classList.remove('visible');
            break;
    }
});

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape' || event.keyCode === 27) {
        console.log("ESC key pressed");
        if (document.getElementById('ticket-details-modal').classList.contains('active')) {
            // If modal is open, just close the modal
            document.getElementById('ticket-details-modal').classList.remove('active');
            currentTicket = null;
        } else {
            // Otherwise close the entire menu
            closeMenu();
        }
    } 
});
        

