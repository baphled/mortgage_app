# Mortgage Application API

A simple Ruby on Rails backend service for managing mortgage applications with affordability assessment.

## Overview

This service provides a JSON API for:
- Submitting mortgage applications
- Retrieving existing applications
- Performing basic affordability assessments

## Prerequisites

- Ruby 3.2 or higher
- SQLite 3 (included with most systems)
- Bundler (`gem install bundler`)

## Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd mortgage-app
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Set up the database:
   ```bash
   bundle exec rails db:create db:migrate
   ```

4. Run the test suite:
   ```bash
   bundle exec rspec
   ```

## How to Run the Application

Start the Rails server:

```bash
bundle exec rails server
```

The API will be available at `http://localhost:3000`.

### API Endpoints

#### 1. Create a Mortgage Application

**Request:**
```bash
curl -X POST http://localhost:3000/api/v1/mortgage_applications \
  -H "Content-Type: application/json" \
  -d '{
    "mortgage_application": {
      "annual_income": 75000,
      "monthly_expenses": 2000,
      "deposit_amount": 50000,
      "property_value": 250000,
      "term_years": 25
    }
  }'
```

**Success Response (201):**
```json
{
  "id": 1,
  "annual_income": 75000,
  "monthly_expenses": 2000,
  "deposit_amount": 50000,
  "property_value": 250000,
  "term": 25,
  "created_at": "2026-05-14T16:38:00.000Z",
  "updated_at": "2026-05-14T16:38:00.000Z"
}
```

**Error Response (422):**
```json
{
  "error": "Validation failed",
  "details": [
    "Annual income must be greater than 0",
    "Property value must be greater than 0"
  ]
}
```

#### 2. Retrieve a Mortgage Application

**Request:**
```bash
curl -X GET http://localhost:3000/api/v1/mortgage_applications/1
```

**Success Response (200):**
```json
{
  "id": 1,
  "annual_income": 75000,
  "monthly_expenses": 2000,
  "deposit_amount": 50000,
  "property_value": 250000,
  "term": 25,
  "created_at": "2026-05-14T16:38:00.000Z",
  "updated_at": "2026-05-14T16:38:00.000Z"
}
```

**Error Response (404):**
```json
{
  "error": "Mortgage application not found"
}
```

#### 3. Perform Affordability Assessment

**Request:**
```bash
curl -X POST http://localhost:3000/api/v1/mortgage_applications/1/affordability_assessment
```

**Success Response (201) - Approved:**
```json
{
  "id": 1,
  "mortgage_application_id": 1,
  "loan_to_value": 80.0,
  "debt_to_income_ratio": 32.0,
  "decision": "approved",
  "max_borrowing_estimate": 656250.0,
  "explanation": "Application meets all affordability criteria: LTV 80.0% (≤80%), debt-to-income 32.0% (≤40%), and sufficient deposit.",
  "created_at": "2026-05-14T16:38:00.000Z",
  "updated_at": "2026-05-14T16:38:00.000Z"
}
```

**Success Response (201) - Declined:**
```json
{
  "id": 2,
  "mortgage_application_id": 2,
  "loan_to_value": 90.0,
  "debt_to_income_ratio": 32.0,
  "decision": "declined",
  "max_borrowing_estimate": 656250.0,
  "explanation": "Application declined: LTV ratio (90.0%) exceeds maximum of 80%.",
  "created_at": "2026-05-14T16:38:00.000Z",
  "updated_at": "2026-05-14T16:38:00.000Z"
}
```

**Error Response (404):**
```json
{
  "error": "Mortgage application not found"
}
```

## How to Run Tests

Run the complete test suite:

```bash
bundle exec rspec
```

Run specific test types:

```bash
# Model tests
bundle exec rspec spec/models/

# Request/integration tests
bundle exec rspec spec/requests/

# Service tests
bundle exec rspec spec/services/
```

## Key Design Decisions

### 1. Service Object Pattern for Business Logic

**Decision:** Extracted affordability calculation logic into a dedicated `AffordabilityAssessor` service object.

**Why:**
- **Separation of Concerns:** Keeps business rules out of controllers and models
- **Testability:** Pure Ruby objects are easier to unit test in isolation
- **Reusability:** The service can be called from controllers, background jobs, or console
- **Maintainability:** Business rules change frequently; having them in one place reduces duplication

**Alternatives Considered:**
- **Model callbacks:** Would tightly couple business logic to persistence
- **Controller methods:** Would make controllers fat and harder to test
- **Concerns:** Would mix business logic with model behavior

### 2. API Versioning with Namespacing

**Decision:** Implemented API endpoints under `/api/v1/` namespace.

**Why:**
- **Future Evolution:** Enables introducing v2 changes without breaking existing clients
- **Clear Contract:** Explicit version communicates stability expectations
- **Routing Organization:** Separates API routes from potential web interface routes

**Trade-off:** Slightly more verbose URLs, but worth it for long-term maintainability.

### 3. Manual JSON Serialization

**Decision:** Implemented manual JSON serialization in controller helper methods rather than using Active Model Serializers.

**Why:**
- **Simplicity:** The response structures are straightforward and unlikely to change frequently
- **Performance:** Avoids the overhead of a serialization layer for simple cases
- **Explicit Control:** Full control over the exact JSON structure returned

**When This Would Change:** If the API grows complex with nested associations, conditional fields, or client-specific formatting, I would reintroduce a proper serialization layer.

## System Evolution

### Current System Boundaries

The current monolithic Rails application handles:
- HTTP request handling
- Business logic (affordability calculations)
- Data persistence
- API response formatting

### Microservice Separation Strategy

For a production mortgage platform, I would evolve toward:

**1. API Gateway Layer**
- Handles authentication, rate limiting, request routing
- Terminates SSL, manages CORS
- Provides unified API documentation

**2. Application Service (Current Rails app)**
- Focus on mortgage application workflow and business rules
- Becomes the core domain service

**3. Assessment Service**
- Dedicated microservice for affordability calculations
- Can be scaled independently based on assessment load
- Enables different calculation engines or third-party integrations

**4. Data Service**
- Separate service for customer data, property data, etc.
- Enables different storage strategies per data type

### Handling Increased Load

**Short-term (1-3 months):**
- Add database indexes on frequently queried columns
- Implement HTTP caching with `ETag` headers for repeated requests
- Add background job processing for assessments

**Medium-term (3-6 months):**
- Database read replicas for reporting queries
- Introduce Redis for session management and rate limiting
- Container-based deployment with Kubernetes for horizontal scaling

**Long-term (6+ months):**
- Implement the microservice separation strategy above
- Add event-driven architecture for real-time updates
- Implement circuit breakers and graceful degradation

### Introducing Asynchronous Processing

**Current:** Assessments run synchronously during the HTTP request

**Evolution Path:**
1. **Immediate:** Wrap assessment logic in ActiveJob for background processing
2. **Short-term:** Implement `202 Accepted` response with job status polling
3. **Medium-term:** WebSocket notifications for assessment completion
4. **Long-term:** Event-sourced architecture with eventual consistency

## Operational Considerations

### Failure Handling

**Request Failures:**
- **Validation errors:** Return 422 with detailed error messages
- **Not found:** Return 404 with consistent error format
- **Server errors:** Return 500 with generic error (no stack traces in production)

**Database Failures:**
- **Connection timeouts:** Implement connection pooling and retry logic
- **Deadlocks:** Add automatic retry with exponential backoff
- **Data corruption:** Regular database integrity checks

### Monitoring and Observability

**Essential Metrics:**
- Request rates and response times by endpoint
- Error rates by type (422, 404, 500)
- Database query performance
- Background job queue depth and success rates

**Logging Strategy:**
```ruby
# Structured logging example
Rails.logger.info "MortgageApplication.created", {
  application_id: mortgage_application.id,
  annual_income: mortgage_application.annual_income,
  property_value: mortgage_application.property_value,
  user_agent: request.user_agent,
  ip_address: request.remote_ip
}
```

**Alerting Rules:**
- Error rate > 5% for 5 minutes
- P95 response time > 2 seconds
- Failed background jobs > 10% of total
- Database connection pool exhaustion

### Data Integrity and Auditability

**Database Constraints:**
- Add `CHECK` constraints for business rules (e.g., `deposit_amount <= property_value`)
- Unique constraints where appropriate
- Foreign key constraints with cascading deletes

**Audit Trail:**
```ruby
class AssessmentAudit < ApplicationRecord
  belongs_to :mortgage_application
  stores :assessment_data, coder: JSON
  
  # Track who made what changes when
  validates :assessed_by, presence: true
  validates :assessment_version, presence: true
end
```

**Compliance Considerations:**
- GDPR: Right to be forgotten requires proper data deletion workflows
- Financial regulations: Immutable audit trails for all decisions
- Data retention: Automated archival of old applications

## Change & Flexibility

### Rules-as-Data Architecture

**Current Problem:** Affordability rules are hardcoded magic numbers in the `AffordabilityAssessor` service.

**Solution:** Implement a database-driven rules engine:

```ruby
class AffordabilityRule < ApplicationRecord
  validates :name, uniqueness: true
  validates :rule_type, inclusion: { in: %w[ltv_threshold dti_threshold deposit_percentage max_income_multiple] }
  validates :value, numericality: { greater_than: 0 }
  validates :active, inclusion: { in: [true, false] }
  
  scope :active, -> { where(active: true) }
end

class RulesEngine
  def self.ltv_threshold
    AffordabilityRule.active.find_by(rule_type: 'ltv_threshold')&.value || 80.0
  end
  
  def self.dti_threshold
    AffordabilityRule.active.find_by(rule_type: 'dti_threshold')&.value || 40.0
  end
end
```

### Admin Interface for Non-Engineering Teams

**Features:**
- Web interface for compliance/risk teams to update rules
- Rule versioning with audit trail
- A/B testing framework for new rules
- Scheduled rule changes (effective dates)

### Hot-Reloading Without Deployment

**Implementation:**
```ruby
class AffordabilityAssessor
  def initialize(mortgage_application, rules_version: nil)
    @mortgage_application = mortgage_application
    @rules = RulesCache.current(rules_version)
  end
  
  private
  
  def rules_version
    @rules || RulesCache.current
  end
end

class RulesCache
  def self.current(version = nil)
    Rails.cache.fetch('affordability_rules', expires_in: 5.minutes) do
      AffordabilityRule.active.to_h { |r| [r.rule_type, r.value] }
    end
  end
end
```

### Rule Versioning and Auditing

**Assessment Snapshot:**
```ruby
class AffordabilityAssessment < ApplicationRecord
  belongs_to :mortgage_application
  
  # Snapshot the rules used for this assessment
  serialize :rules_snapshot, JSON
  
  before_create :snapshot_rules
  
  private
  
  def snapshot_rules
    self.rules_snapshot = RulesCache.current.as_json
  end
end
```

## Trade-offs & Prioritisation

### What I Deliberately Kept Simple

**1. No Authentication**
- **Why:** The technical test specifically stated this was optional
- **Trade-off:** No security, but faster delivery of core functionality
- **Next-step:** Add HTTP Basic Auth or JWT authentication

**2. SQLite Database**
- **Why:** Simpler setup for reviewers; works out of the box
- **Trade-off:** Not production-ready for high concurrency
- **Next-step:** Migrate to PostgreSQL with connection pooling

**3. Synchronous Assessments**
- **Why:** Simpler to implement and test
- **Trade-off:** Poor user experience for complex calculations
- **Next-step:** Background jobs with WebSocket notifications

**4. Manual JSON Serialization**
- **Why:** Avoided dependency overhead for simple responses
- **Trade-off:** More tedious to modify response structure
- **Next-step:** Introduce proper serialization layer as API grows

### What I Left Out Entirely

**1. Comprehensive Error Handling**
- **Why:** Focused on happy path and basic validation errors
- **Trade-off:** Poor debugging information for edge cases
- **Next-step:** Structured error responses with error codes

**2. Pagination and Filtering**
- **Why:** Single application retrieval meets requirements
- **Trade-off:** Won't scale to large datasets
- **Next-step:** Add pagination for assessment history endpoints

**3. Rate Limiting**
- **Why:** Not specified in requirements
- **Trade-off:** Vulnerable to DoS attacks
- **Next-step:** Implement Redis-based rate limiting

### 1-2 Week Prioritisation

**Week 1: Production Readiness**
1. **Authentication** (Priority: Critical)
   - Add HTTP Basic Auth or JWT
   - User model with roles (applicant, admin, underwriter)

2. **Database Hardening** (Priority: High)
   - Migration to PostgreSQL
   - Database constraints for all business rules
   - Connection pooling configuration

3. **Background Jobs** (Priority: High)
   - ActiveJob integration
   - Async assessment processing
   - Job monitoring and retry logic

**Week 2: Enhanced Features**
4. **Rules Engine** (Priority: Medium)
   - Database-driven affordability rules
   - Admin interface for rule management
   - Rule versioning and auditing

5. **Monitoring** (Priority: Medium)
   - Structured logging implementation
   - Performance metrics collection
   - Basic alerting setup

6. **API Enhancements** (Priority: Low)
   - Assessment history endpoint
   - Pagination support
   - API documentation (OpenAPI/Swagger)

### Key Technical Debt

**1. Business Logic Coupling**
- **Issue:** Affordability rules are scattered across model and service
- **Impact:** Hard to modify rules without touching multiple files
- **Solution:** Extract to a dedicated rules engine module

**2. Error Handling Inconsistency**
- **Issue:** Some endpoints return different error formats
- **Impact:** Poor API client experience
- **Solution:** Standardized error response wrapper

**3. Missing Database Constraints**
- **Issue:** Business rules only validated at model level
- **Impact:** Data integrity risks from raw SQL or other models
- **Solution:** Add CHECK constraints and database validations

This implementation focuses on delivering a solid foundation that can evolve into a production mortgage platform. The architecture supports growth while maintaining the simplicity required for the technical exercise.