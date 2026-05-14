# Mortgage Application API

A Rails API-only backend service for managing mortgage applications and affordability assessments.

## Features

- **Mortgage Application Management**: Create and retrieve mortgage applications
- **Affordability Assessment**: Automated assessment based on LTV, debt-to-income ratio, and deposit requirements
- **RESTful API**: Versioned JSON API with proper error handling
- **Comprehensive Testing**: Full test coverage for models, services, and endpoints

## API Endpoints

### Version 1

#### POST /api/v1/mortgage_applications
Create a new mortgage application.

**Request Body:**
```json
{
  "mortgage_application": {
    "annual_income": 75000,
    "monthly_expenses": 2000,
    "deposit_amount": 60000,
    "property_value": 300000,
    "term_years": 25
  }
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "annual_income": 75000.0,
  "monthly_expenses": 2000.0,
  "deposit_amount": 60000.0,
  "property_value": 300000.0,
  "term": 25,
  "created_at": "2026-05-14T16:27:14.008Z",
  "updated_at": "2026-05-14T16:27:14.008Z"
}
```

#### GET /api/v1/mortgage_applications/:id
Retrieve a mortgage application by ID.

**Response (200 OK):**
```json
{
  "id": 1,
  "annual_income": 75000.0,
  "monthly_expenses": 2000.0,
  "deposit_amount": 60000.0,
  "property_value": 300000.0,
  "term": 25,
  "created_at": "2026-05-14T16:27:14.008Z",
  "updated_at": "2026-05-14T16:27:14.008Z"
}
```

#### POST /api/v1/mortgage_applications/:id/affordability_assessment
Perform affordability assessment on a mortgage application.

**Response (201 Created):**
```json
{
  "id": 1,
  "mortgage_application_id": 1,
  "loan_to_value": 80.0,
  "debt_to_income_ratio": 32.0,
  "decision": "approved",
  "max_borrowing_estimate": 656250.0,
  "explanation": "Application meets all affordability criteria: LTV 80.0% (≤80.0%), debt-to-income 32.0% (≤40.0%), and sufficient deposit.",
  "created_at": "2026-05-14T16:29:00.116Z",
  "updated_at": "2026-05-14T16:29:00.116Z"
}
```

## Affordability Assessment Rules

The affordability assessment evaluates applications based on three criteria:

### 1. Loan-to-Value (LTV) Ratio
- **Formula**: LTV = (property_value - deposit_amount) / property_value × 100
- **Requirement**: LTV ≤ 80%

### 2. Debt-to-Income Ratio
- **Formula**: Debt-to-income = monthly_expenses / (annual_income / 12) × 100
- **Requirement**: Debt-to-income ≤ 40%

### 3. Deposit Requirement
- **Requirement**: deposit_amount ≥ property_value × 10%

### Decision Logic
Applications are approved only if ALL THREE criteria are met. If any criterion fails, the application is declined with an explanation of which rules were violated.

### Maximum Borrowing Estimate
- **Formula**: Maximum borrowing = (annual_income / 12) × 0.35 × (term_years × 12)
- This represents the maximum loan amount based on 35% of monthly income over the loan term.

## Setup Instructions

### Prerequisites
- Ruby 3.4.4+
- Rails 8.1.3+
- SQLite3 (development/test) or PostgreSQL (production)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd mortgage_app
```

2. Install dependencies:
```bash
bundle install
```

3. Set up the database:
```bash
# For development (SQLite)
bin/rails db:create db:migrate

# For production (PostgreSQL)
# Ensure PostgreSQL is running and configure config/database.yml
RAILS_ENV=production bin/rails db:create db:migrate
```

### Running the Application

Start the Rails server:
```bash
# Development
bin/rails server

# Production
RAILS_ENV=production bin/rails server
```

The API will be available at `http://localhost:3000`.

### Running Tests

Execute the test suite:
```bash
bin/rspec
```

The test suite includes:
- Model specs for validations and calculations
- Service specs for affordability assessment logic
- Request specs for all API endpoints

## Key Design Decisions

### 1. Service Object Pattern for Business Logic
I chose to implement the affordability assessment logic using a service object (`AffordabilityAssessor`) rather than placing it in the model or controller. This decision provides:

- **Clear separation of concerns**: Business logic is isolated from persistence and presentation concerns
- **Testability**: The service can be unit tested independently of Rails components
- **Reusability**: The assessment logic can be used in multiple contexts (controllers, background jobs, etc.)
- **Maintainability**: Complex rules are easier to modify and extend when encapsulated in a single class

The `AffordabilityAssessor` follows a simple interface with a `call` method that returns a result object, making it easy to understand and use.

### 2. Versioned API Structure
I implemented a versioned API structure (`Api::V1`) for the following reasons:

- **Future-proofing**: Allows for breaking changes in future versions without affecting existing clients
- **Clear contract**: Versioning provides a stable API contract for consumers
- **Documentation**: Makes the API structure and available endpoints explicit
- **Flexibility**: Different versions can coexist, supporting gradual migration paths

The versioning is implemented using Rails namespaces, which is a standard and well-understood pattern in the Rails ecosystem.

### 3. Comprehensive Error Handling Strategy
I designed a comprehensive error handling strategy that covers:

- **Validation errors**: Proper 422 responses with detailed error messages
- **Not found errors**: 404 responses for missing resources
- **Server errors**: Graceful 500 responses with error logging
- **Consistent format**: All error responses follow a consistent JSON structure

This approach ensures that API clients receive meaningful feedback and can handle errors appropriately. The error handling is centralized in the `ApplicationController` to maintain consistency across all endpoints.

## System Evolution

### Current Implementation
The current implementation is a monolithic Rails API with all components contained within a single application:
- Web API layer
- Business logic layer
- Data persistence layer
- Background processing (if needed)

### Production Evolution Plan

#### System Boundaries
For a production mortgage platform, I would evolve the system into a microservices architecture with clear boundaries:

**Core Mortgage Service (this API)**
- Remains responsible for mortgage application management and affordability assessment
- Focuses on domain logic and business rules

**Separate Services to Extract:**
1. **Customer Service**: Manages customer profiles, authentication, and authorization
2. **Property Service**: Handles property information, valuations, and market data
3. **Document Service**: Manages document upload, storage, and verification
4. **Notification Service**: Handles email, SMS, and push notifications
5. **Reporting Service**: Provides analytics and reporting capabilities

#### Handling Increased Load
To handle increased load in a production environment:

1. **Database Optimization**
   - Implement read replicas for reporting queries
   - Add database connection pooling
   - Consider database sharding for very large datasets

2. **Caching Strategy**
   - Add Redis caching for frequently accessed data
   - Implement HTTP caching for API responses
   - Cache affordability assessment results for similar applications

3. **Background Processing**
   - Move affordability assessments to background jobs using Sidekiq
   - Implement asynchronous processing for report generation
   - Use message queues for inter-service communication

4. **Infrastructure Scaling**
   - Containerize the application using Docker
   - Deploy to Kubernetes for orchestration
   - Implement auto-scaling based on traffic patterns

#### Introducing Asynchronous Processing
The affordability assessment process would benefit from asynchronous processing:

1. **Immediate Response Enhancement**
   - Accept application and return 202 Accepted with assessment job ID
   - Provide a status endpoint to check assessment progress
   - Send notifications when assessment is complete

2. **Background Job Implementation**
   ```ruby
   class AffordabilityAssessmentJob < ApplicationJob
     def perform(mortgage_application_id)
       application = MortgageApplication.find(mortgage_application_id)
       result = AffordabilityAssessor.new(application).call
       
       application.affordability_assessments.create!(
         loan_to_value: result.loan_to_value,
         debt_to_income_ratio: result.debt_to_income_ratio,
         decision: result.decision,
         max_borrowing_estimate: result.max_borrowing_estimate,
         explanation: result.explanation
       )
     end
   end
   ```

3. **Webhook Integration**
   - Allow clients to register webhooks for assessment completion
   - Provide payload security verification

## Operational Considerations

### Failure Handling
To ensure system reliability in production:

1. **Circuit Breakers**
   - Implement circuit breakers for external service dependencies
   - Graceful degradation when non-critical services fail

2. **Retry Mechanisms**
   - Add exponential backoff for transient failures
   - Dead letter queues for failed background jobs

3. **Health Checks**
   - Implement comprehensive health check endpoints
   - Monitor database connectivity, external service status, and background job queues

4. **Graceful Degradation**
   - When under heavy load, prioritize core mortgage application functionality
   - Temporarily disable non-critical features

### Monitoring and Observability
Production-grade monitoring requires:

1. **Application Metrics**
   - Track request rates, response times, and error rates
   - Monitor business metrics (applications per day, approval rates)
   - Set up alerts for abnormal patterns

2. **Infrastructure Monitoring**
   - Monitor CPU, memory, and disk usage
   - Track database performance metrics
   - Monitor background job queues

3. **Distributed Tracing**
   - Implement tracing to follow requests across service boundaries
   - Identify performance bottlenecks in complex workflows

4. **Logging Strategy**
   - Structured logging with correlation IDs
   - Log key business events with relevant context
   - Ensure logs are searchable and have appropriate retention

### Data Integrity and Auditability
For financial applications, data integrity is crucial:

1. **Database Constraints**
   - Ensure all business rules are enforced at the database level
   - Use database transactions for multi-step operations
   - Implement foreign key constraints for relationships

2. **Audit Logging**
   - Log all changes to mortgage applications with user information
   - Maintain an immutable audit trail of affordability assessments
   - Store historical snapshots of application data

3. **Data Validation**
   - Validate all input data against business rules
   - Implement cross-field validation (e.g., deposit ≤ property_value)
   - Use Rails strong parameters to prevent mass assignment vulnerabilities

4. **Backup Strategy**
   - Regular database backups with verified restoration
   - Off-site backup storage
   - Documented disaster recovery procedures

## Change & Flexibility

Affordability rules change frequently and may need to be updated by non-engineering teams. To support this:

### 1. Configuration-Driven Rules
Move affordability rules to configuration files or database tables:

```ruby
class AffordabilityRules
  def self.max_ltv
    Rails.cache.fetch('affordability_rules/max_ltv') do
      RuleSet.find_by_key('max_ltv')&.value || 80.0
    end
  end
  
  def self.max_debt_to_income
    Rails.cache.fetch('affordability_rules/max_debt_to_income') do
      RuleSet.find_by_key('max_debt_to_income')&.value || 40.0
    end
  end
  
  def self.min_deposit_percentage
    Rails.cache.fetch('affordability_rules/min_deposit_percentage') do
      RuleSet.find_by_key('min_deposit_percentage')&.value || 10.0
    end
  end
end
```

### 2. Admin Interface
Create an admin interface for rule management:

- **Rule Management Page**: Allow authorized users to view and modify rules
- **Rule Validation**: Ensure changes don't break existing functionality
- **Version Control**: Track rule changes and allow rollback
- **Change History**: Audit trail of who changed what and when

### 3. Rule Evaluation Engine
Implement a flexible rule evaluation engine:

```ruby
class RuleEvaluator
  def self.evaluate(application, rules)
    results = {}
    
    rules.each do |rule|
      results[rule.key] = {
        passed: rule.evaluate(application),
        value: rule.calculate_value(application),
        threshold: rule.threshold
      }
    end
    
    results
  end
end
```

### 4. Deployment Strategy
To support rule changes without redeployment:

1. **Rule Caching**: Cache rules in memory with TTL-based expiration
2. **Hot Reload**: Implement endpoints to reload rules without restarting
3. **Staged Rollout**: Test new rules on a subset of applications
4. **A/B Testing**: Compare results from different rule sets

## Trade-offs & Prioritisation

Given the time constraints for this technical test, I made several deliberate trade-offs:

### 1. Simplicity Over Flexibility
I prioritised a simple, straightforward implementation over a more flexible but complex solution:

- **Single Database**: Used SQLite instead of PostgreSQL for simplicity
- **Basic Authentication**: Omitted authentication to focus on core functionality
- **Synchronous Processing**: Implemented synchronous affordability assessment instead of async

**Reasoning**: The technical test requirements focused on demonstrating understanding of Rails, API design, and business logic implementation. These simplifications allowed me to deliver a complete, working solution within the time constraints.

### 2. Limited Error Scenarios
I focused on happy path and basic error handling rather than comprehensive edge cases:

- **Basic Validation**: Implemented only the essential validations
- **Simple Error Messages**: Used generic error messages instead of detailed, user-friendly explanations
- **Limited Input Sanitization**: Relied on Rails defaults rather than custom sanitization

**Reasoning**: The goal was to demonstrate the ability to create a functional API with proper error handling. Comprehensive error handling would have required significantly more time without adding much value to the core demonstration.

### 3. Testing Scope
I prioritised testing the most critical components:

- **Core Business Logic**: Full test coverage for affordability calculations
- **API Endpoints**: Basic request/response testing
- **Model Validations**: Essential validation testing

**Omitted Testing:**
- **Integration Tests**: End-to-end workflow testing
- **Performance Testing**: Load testing and benchmarking
- **Security Testing**: Vulnerability testing

**Reasoning**: Testing time needed to be balanced against implementation time. I focused on tests that would verify the core functionality and business rules, which are the most important aspects of the mortgage application.

### 4. Infrastructure Considerations
I made infrastructure trade-offs to focus on application development:

- **No Dockerfile**: Omitted containerization to focus on Rails implementation
- **No Deployment Scripts**: Basic setup instructions instead of deployment automation
- **Limited Configuration**: Environment-based configuration without complex settings management

**Reasoning**: The technical test is about demonstrating Rails and API development skills, not DevOps capabilities. Infrastructure considerations were simplified to maintain focus on the core requirements.

## Next Steps (1-2 Week Prioritisation)

If I were to continue developing this system over the next 1-2 weeks, I would prioritise the following improvements:

### 1. Enhanced Error Handling and Validation (Priority: High)
**Time Estimate**: 2-3 days
**Why**: This directly improves user experience and system robustness
**Tasks**:
- Add detailed validation error messages
- Implement more comprehensive input validation
- Add error context (request ID, timestamp) to all error responses
- Create custom exception classes for different error types

### 2. Authentication and Authorization (Priority: High)
**Time Estimate**: 2-3 days
**Why**: Essential for any production application handling sensitive financial data
**Tasks**:
- Implement JWT-based authentication
- Add role-based authorization
- Secure endpoints with authentication middleware
- Add user management capabilities

### 3. Background Processing (Priority: Medium)
**Time Estimate**: 2-3 days
**Why**: Improves performance and user experience for long-running processes
**Tasks**:
- Integrate Sidekiq for background job processing
- Make affordability assessments asynchronous
- Add job status monitoring and notifications
- Implement retry logic for failed jobs

### 4. Test Suite Enhancement (Priority: Medium)
**Time Estimate**: 2-3 days
**Why**: Ensures system reliability and maintainability
**Tasks**:
- Add integration tests for complete workflows
- Implement contract testing for API consumers
- Add performance benchmarks
- Increase test coverage to 95%+

### 5. Documentation and Developer Experience (Priority: Low)
**Time Estimate**: 1-2 days
**Why**: Improves onboarding and maintenance efficiency
**Tasks**:
- Add OpenAPI/Swagger documentation
- Create developer setup scripts
- Add inline code documentation
- Implement API versioning strategy documentation

This prioritisation focuses on delivering immediate value by improving system robustness, security, and performance, while laying the groundwork for future scalability and maintainability.
